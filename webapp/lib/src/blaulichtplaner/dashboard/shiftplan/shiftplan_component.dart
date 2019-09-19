import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workarea_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/location_switcher/location_switcher_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_manager_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart' as models;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shift_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shift_editor_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shift_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shiftplan_editor_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shiftplan_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/utils/company_aware.dart';
import 'package:firebase/firestore.dart';

import 'routes.dart';

@Component(selector: 'blp-shiftplan', templateUrl: 'shiftplan_component.html', directives: [
  materialDirectives,
  coreDirectives,
  routerDirectives,
  formDirectives,
  ShiftComponent,
  ShiftEditorComponent,
  ShiftplanEditorComponent,
  DeferredContentDirective,
  LocationSwitcherComponent
], providers: [
  popupBindings,
  materialProviders,
  ClassProvider(Routes),
  ClassProvider(ShiftService),
  ClassProvider(WorkAreaResolver),
  ClassProvider(EmployeeManagerService)
])
class ShiftplanComponent extends Object with CompanyAware implements OnActivate, OnInit, OnDestroy {
  final Routes routes;
  final ContextService contextService;
  @ViewChild("shiftplanPopup")
  DropdownHandle shiftplanPopupHandle;
  final FirebaseService _firebaseService;
  final ShiftService _shiftService;
  final EmployeeManagerService _employeeManagerService;
  final WorkAreaService _workAreaService;
  final WorkAreaResolver workAreaResolver;
  String _selectedShiftplanPath;
  final SelectionModel<FirestoreSelectOption> selectedShiftplan = new SelectionModel.single();
  SelectionOptions<FirestoreSelectOption> shiftplanOptions = SelectionOptions.fromList([]);

  List<TransportResult<LocationWorkArea>> workAreasList;
  ItemRenderer employeeRenderer = (tr) => tr.data.uiDisplayName;

  SelectionOptions<TransportResult<models.Employee>> possibleEmployees;
  SelectionModel<TransportResult<models.Employee>> selectedEmployee = new SelectionModel.single();

  ShiftplanModel shiftplanModel = ShiftplanModel();
  ShiftplanData shiftplanData;
  Shift shift;
  bool hasWorkAreas = false;
  bool showShiftEditor = false;


  String get selectionShiftplanLabel => selectedShiftplan.selectedValues.length > 0
      ? renderShiftplanOption(selectedShiftplan.selectedValues.first)
      : 'Dienstplan auswählen';

  ShiftplanComponent(this.routes, this.contextService, this._firebaseService, this._shiftService,
      this._employeeManagerService, this._workAreaService, this.workAreaResolver) {
    print("(${this.hashCode}) ShiftplanComponent created");

    selectedShiftplan.selectionChanges.listen((changes) {
      print("(${this.hashCode}) selectedShiftplan changed, length ${changes.length}");
      var selectedShiftplanPath = null;
      for (SelectionChangeRecord change in changes) {
        if (change.added.length > 0) {
          final newSelection = change.added.first;
          selectedShiftplanPath = newSelection.path;
        }
      }
      _selectShiftplan(selectedShiftplanPath);
    });
  }

  cancel() {
    shiftplanPopupHandle.close();
  }

  saveShiftplan(ShiftplanModel shiftplanModel) async {
    SelectedElement selectedLocation = contextService.selectedCompanyLocation;
    DocumentReference selectedCompanyRef = contextService.selectedCompany.ref;

    Date startDate = shiftplanModel.range.range.start;
    Date endDate = shiftplanModel.range.range.end;
    DateTime startTime = new DateTime(startDate.year, startDate.month, startDate.day);
    DateTime endTime = new DateTime(endDate.year, endDate.month, endDate.day).add(new Duration(days: 1));

    Shiftplan shiftplan = new Shiftplan(startTime, endTime, shiftplanModel.label,
        shiftplanModel.status.selectedValues.first, selectedLocation.ref, selectedLocation.name);

    final shiftplanRef = await _firebaseService.saveShiftplan(selectedCompanyRef, shiftplan);
    shiftplanPopupHandle.close();
    if (contextService.selectedCompanyLocation != null) {
      await _initShiftplan(contextService.selectedCompany, contextService.selectedCompanyLocation,
          preselectShiftplanRef: shiftplanRef);
    }
  }

  _selectShiftplan(String shiftplanPath) async {
    shiftplanData?.clear();
    _selectedShiftplanPath = shiftplanPath;
    print("(${this.hashCode}) Loading shiftplan at ${shiftplanPath}");
    if (shiftplanPath != null) {
      DocumentSnapshot snapshot = await _firebaseService.loadShiftplan(shiftplanPath);
      if (snapshot.exists) {
        final shiftplan = Shiftplan.fromSnapshot(snapshot);
        _initShiftplanData(shiftplan);
      } else {
        shiftplanData = null;
      }
    } else {
      shiftplanData = null;
    }
  }

  void _initShiftplanData(Shiftplan shiftplan) {
    shiftplanData = ShiftplanData.withShiftplan(workAreaResolver, _firebaseService.firestore, shiftplan)
      ..listenForShifts()
      ..listenForAssignments()
      ..listenForBids();
  }

  bool get shiftplanPlanning => shiftplanData != null && shiftplanData.planning;

  publishShiftplan() async {
    // TODO loader anzeigen
    await ShiftplanService.publishShiftplan(shiftplanData.selfRef);
    _initShiftplan(contextService.selectedCompany, contextService.selectedCompanyLocation,
        preselectShiftplanRef: shiftplanData.selfRef);
  }

  clearSelection() {
    shiftplanData.selectedShifts.clear();
  }

  deleteSelected() async {
    for (final shift in shiftplanData.selectedShifts.selectedValues) {
      await _shiftService.deleteShift(shift.shiftRef);
    }
    clearSelection();
  }

  createShiftplan() {
    shiftplanPopupHandle.open();
  }

  assignEmployee() {
    if (shiftplanData.selectedShifts.isNotEmpty && selectedEmployee.isNotEmpty) {
      final assignedEmployees =
          selectedEmployee.selectedValues.map((tr) => SelectablePath(tr.selfRef.path, tr.data.uiDisplayName)).toList();

      _shiftService.assignEmployeesToShifts(assignedEmployees, shiftplanData.selectedShifts.selectedValues);
      clearSelection();
    } else {
      print("Keine Dienste oder keine Mitarbeiter ausgewählt");
    }
  }

  String renderShiftplanOption(FirestoreSelectOption option) => option.uiDisplayName;

  addShift(ShiftDay shiftDay) {
    final day = shiftDay.day;
    shift = new Shift.empty(_firebaseService.firestore.doc(_selectedShiftplanPath), contextService.selectedCompany.ref);
    shift.locationLabel = contextService.selectedCompanyLocation.name;
    shift.locationRef = contextService.selectedCompanyLocation.ref;
    shift.from = new DateTime(day.year, day.month, day.day);
    shift.to = new DateTime(day.year, day.month, day.day);
    showShiftEditor = true;
  }

  editShift(Shift shiftToEdit) {
    shift = shiftToEdit;
    showShiftEditor = true;
  }

  cancelShiftEditor() {
    showShiftEditor = false;
  }

  saveShiftEditor(ShiftModel shift) {
    _shiftService.saveShift(shift);
    showShiftEditor = false;
  }

  deleteShiftEditor(ShiftModel shift) {
    _shiftService.deleteShift(shift.shiftRef);
    showShiftEditor = false;
  }

  @override
  Future onActivate(RouterState previous, RouterState current) async {
    print("(${this.hashCode}) shiftplanComponent: onActivate ${contextService.selectedCompanyLocation}");
    if (contextService.selectedCompanyLocation != null) {
      await initWithCompanyAndLocation();
    }
  }

  @override
  Future initWithCompanyAndLocation() async {
    await _initWorkareas(contextService.selectedCompanyLocation);
    await _initEmployeeList(contextService.selectedCompany);
    await _initShiftplan(contextService.selectedCompany, contextService.selectedCompanyLocation);
  }

  Future _initWorkareas(SelectedElement selectedCompanyLocation) async {
    hasWorkAreas = false;
    workAreasList = await _workAreaService.getWorkAreaForCompanyAndLocation(selectedCompanyLocation.ref);
    hasWorkAreas = workAreasList != null && workAreasList.isNotEmpty;
    workAreaResolver.init(workAreasList);
  }

  Future _initShiftplan(SelectedElement selectedCompany, SelectedElement selectedCompanyLocation,
      {DocumentReference preselectShiftplanRef}) async {
    final querySnapshot = await _firebaseService.selectShiftplans(selectedCompany.ref, selectedCompanyLocation.ref);
    List<Shiftplan> shiftplans = [];
    if (!querySnapshot.empty) {
      querySnapshot.forEach((doc) {
        shiftplans.add(Shiftplan.fromSnapshot(doc));
      });
      // FIXME let firestore order this
      shiftplans.sort((s1, s2) => s1.from.compareTo(s2.from));

      List<FirestoreSelectOption> selectOptions =
          shiftplans.map((sp) => FirestoreSelectOption(sp.selfRef, sp.uiDisplayName)).toList();

      shiftplanOptions = SelectionOptions.fromList(selectOptions);
      selectedShiftplan.clear();
      if (selectOptions.length > 0) {
        final now = DateTime.now();

        int currentIndex = -1;
        if (preselectShiftplanRef != null) {
          currentIndex = shiftplans.indexWhere((sp) => sp.selfRef.path == preselectShiftplanRef.path);
        } else {
          currentIndex = shiftplans.indexWhere((sp) => sp.from.isBefore(now) && sp.to.isAfter(now));
        }
        if (currentIndex == -1) {
          currentIndex = 0;
        }
        selectedShiftplan.select(selectOptions[currentIndex]);
      }
    } else {
      shiftplanOptions = SelectionOptions.fromList([]);
      selectedShiftplan.clear();
    }
  }

  Future _initEmployeeList(SelectedElement selectedCompany) async {
    final employeeList = await _employeeManagerService.getEmployees(selectedCompany.ref.id);
    possibleEmployees =
        new StringSelectionOptions(employeeList, toFilterableString: employeeRenderer, shouldSort: true);
  }

  @override
  void ngOnDestroy() {
    cancelListener();
  }

  @override
  void ngOnInit() {
    initCompanyListener(contextService);
  }
}
