import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workarea_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/evaluation/evaluation_editor_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/location_switcher/location_switcher_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shift_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shift_editor_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shift_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shiftplan_editor_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/widgets/pipes.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:firebase/firestore.dart';

@Component(selector: 'blp-evaluation', templateUrl: 'evaluation_component.html', directives: [
  materialDirectives,
  coreDirectives,
  routerDirectives,
  formDirectives,
  ShiftComponent,
  ShiftEditorComponent,
  ShiftplanEditorComponent,
  DeferredContentDirective,
  LocationSwitcherComponent,
  EvaluationEditorComponent
], providers: [
  popupBindings,
  materialProviders,
  ClassProvider(ShiftService),
  ClassProvider(WorkAreaResolver)
], pipes: [
  DurationPipe
])
class EvaluationComponent implements OnActivate, OnInit, OnDestroy {
  final ContextService contextService;
  final FirebaseService _firebaseService;
  final WorkAreaService _workAreaService;
  final WorkAreaResolver workAreaResolver;
  final SelectionModel<FirestoreSelectOption> selectedShiftplan = new SelectionModel.single();
  SelectionOptions<FirestoreSelectOption> shiftplanOptions = SelectionOptions.fromList([]);

  List<TransportResult<LocationWorkArea>> workAreasList;
  ItemRenderer employeeRenderer = (tr) => tr.data.uiDisplayName;

  ShiftplanModel shiftplanModel = ShiftplanModel();
  ShiftplanData shiftplanData;
  Shift shift;
  bool showEvaluationEditor = false;

  StreamSubscription<SelectedElement> _locationSubscription;

  String get selectionShiftplanLabel => selectedShiftplan.selectedValues.length > 0
      ? renderShiftplanOption(selectedShiftplan.selectedValues.first)
      : 'Dienstplan auswählen';

  EvaluationComponent(this.contextService, this._firebaseService, this._workAreaService, this.workAreaResolver) {
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

  _selectShiftplan(String shiftplanPath) async {
    shiftplanData?.clear();
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
      ..listenForEvaluations()
      ..listenForAssignments();
  }

  bool get shiftplanPlanning => shiftplanData != null && shiftplanData.planning;

  clearSelection() {
    shiftplanData.selectedShifts.clear();
  }

  String renderShiftplanOption(FirestoreSelectOption option) => option.uiDisplayName;

  editShift(Shift shiftToEdit) {
    print("edit shifts ${shiftToEdit}");
    shift = shiftToEdit;
    showEvaluationEditor = true;
    //shiftPopupHandle.open();
  }

  cancelEvaluationEditor() {
    showEvaluationEditor = false;
    //shiftPopupHandle.close();
  }

  @override
  Future onActivate(RouterState previous, RouterState current) async {
    print("(${this.hashCode}) shiftplanComponent: onActivate ${contextService.selectedCompanyLocation}");
    if (contextService.selectedCompanyLocation != null) {
      await _initWithCompanyAndLocation();
    }
  }

  Future _initWithCompanyAndLocation() async {
    await _initWorkareas(contextService.selectedCompanyLocation);
    await _initShiftplan(contextService.selectedCompany, contextService.selectedCompanyLocation);
  }

  Future _initWorkareas(SelectedElement selectedCompanyLocation) async {
    workAreasList = await _workAreaService.getWorkAreaForCompanyAndLocation(selectedCompanyLocation.ref);
    workAreaResolver.init(workAreasList);
  }

  Future _initShiftplan(SelectedElement selectedCompany, SelectedElement selectedCompanyLocation,
      {DocumentReference preselectShiftplanRef}) async {
    final querySnapshot = await _firebaseService.selectShiftplans(selectedCompany.ref, selectedCompanyLocation.ref,
        onlyPublic: true, maxFromDate: DateTime.now());
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
  
  @override
  void ngOnDestroy() {
    shiftplanData?.clear();
    print("(${this.hashCode}) ngOnDestroy: ${_locationSubscription}");
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
      print("(${this.hashCode}) subscription cancelled: ${_locationSubscription}");
      _locationSubscription = null;
    }
  }

  @override
  void ngOnInit() {
    print("(${this.hashCode}) ngOnInit: ${_locationSubscription}");
    if (_locationSubscription == null) {
      _locationSubscription = contextService.onLocation.listen((selectedLocation) {
        print("(${this.hashCode}) location changed: $selectedLocation");
        _initWithCompanyAndLocation();
      });
    }
  }
}
