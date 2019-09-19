import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workinghours_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/employee_select_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart' as models;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/date_utils.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/utils/components_utils.dart';

@Directive(
    selector: '[shift-validator]', providers: const [const ExistingProvider.forToken(NG_VALIDATORS, ShiftValidator)])
class ShiftValidator implements Validator {
  @override
  Map<String, dynamic> validate(AbstractControl control) {
    Map<String, dynamic> result = {};
    //print("validate value: ${control.value}");
    if (control is ControlGroup) {
      control.controls.forEach((key, control) {});
    }
    return result;
  }
}

@Component(selector: 'blp-shift-editor', templateUrl: 'shift_editor_component.html', directives: [
  materialDirectives,
  coreDirectives,
  routerDirectives,
  formDirectives,
  ShiftValidator,
  DateTimePickerValueAccessor,
  EmployeeSelectComponent
], providers: [
  materialProviders,
  ClassProvider(WorkingHoursService)
], pipes: [
  DatePipe
])
class ShiftEditorComponent implements OnChanges, CanReuse {
  ShiftModel shiftModel;
  final ContextService _contextService;
  final WorkingHoursService _workingHoursService;

  SelectionOptions<FirestoreSelectOption> workAreaOptions = SelectionOptions.fromList([]);
  List<WorkingHours> workingHoursList = [];

  @ViewChild('shiftForm')
  NgForm form;

  DateTime minDateTime;
  DateTime maxDateTime;
  
  DocumentReference companyRef;

  ShiftplanData _shiftplanData;

  ShiftplanData get shiftplanData => _shiftplanData;

  @Input("shiftplanData")
  set shiftplanData(ShiftplanData value) {
    _shiftplanData = value;
    final firstDateTime = _shiftplanData.firstDateTime();
    if (firstDateTime != null) {
      minDateTime = firstDateTime.subtract(new Duration(days: 2));
    }
    final lastDateTime = _shiftplanData.lastDateTime();
    if (lastDateTime != null) {
      maxDateTime = lastDateTime.add(new Duration(days: 2));
    }
  }
  
  @Input("shift")
  set shift(Shift value) {
    shiftModel = ShiftModel.fromShift(value);
  }

  @Input("workAreasList")
  List<TransportResult<LocationWorkArea>> workAreasList;

  final _cancel = new StreamController<Null>();

  ShiftEditorComponent(this._contextService, this._workingHoursService);

  @Output()
  Stream<ShiftDay> get onCancel => _cancel.stream;

  cancel() {
    form.controls.forEach((key, control) {
      print("${key}: ${control.value}");
    });
    _cancel.add(null);
  }

  acceptBid(Bid bid) async {
    DocumentSnapshot snapshot = await bid.employeeRef.get();
    final employee = models.Employee.fromSnapshot(snapshot);
    shiftModel.assignedEmployees.select(SelectablePath(snapshot.ref.path, employee.uiDisplayName));
  }

  isBidAcceptable(Bid bid) {
    return !shiftModel.assignedEmployees.isSelected(SelectablePath(bid.employeeRef.path, null));
  }

  selectWorkingHours(WorkingHours workingHours) {
    Date startDate = Date.fromTime(shiftModel.from);
    shiftModel.from = DateTimeUtils.dateTimeWithTimeFrom(startDate, workingHours.from);
    shiftModel.to = DateTimeUtils.dateTimeWithEndTime(startDate, workingHours);
  }

  final _save = new StreamController<ShiftModel>();
  final _delete = new StreamController<ShiftModel>();

  @Output()
  Stream<ShiftModel> get onSave => _save.stream;

  @Output()
  Stream<ShiftModel> get onDelete => _delete.stream;

  save() {
    if (shiftModel.from.isBefore(shiftModel.to)) {
      shiftModel.status = _shiftplanData.planning ? Shiftplan.STATUS_PLANNING : Shiftplan.STATUS_PUBLIC;
      _save.add(shiftModel);
    } else {
      print("startzeit nach endzeit");
    }
  }

  delete() {
    _delete.add(shiftModel);
  }

  String get selectionWorkAreaLabel => shiftModel.workArea;

  repeatShift(Date dateTime, bool selected) {
    if (selected) {
      shiftModel.repeatDates.add(dateTime);
    } else {
      shiftModel.repeatDates.remove(dateTime);
    }
  }

  selectAllRepeatDays() {
    for (ShiftWeek week in shiftplanData.shiftWeeks) {
      for (ShiftDay day in week.shiftDays) {
        if (day.partOfShiftplan && canRepeatDay(day)) {
          shiftModel.repeatDates.add(day.day);
        }
      }
    }
  }

  startTimeChanged(DateTime dateTime) {
    shiftModel.from = dateTime;
    shiftModel.repeatDates.remove(new Date(dateTime.year, dateTime.month, dateTime.day));
  }

  bool canRepeatDay(ShiftDay shiftDay) {
    return !DateTimeUtils.isSameDate(shiftDay.day, shiftModel.from);
  }

  renderWorkAreaOption(FirestoreSelectOption selectOption) => selectOption.uiDisplayName;
  
  @override
  Future ngOnChanges(Map<String, SimpleChange> changes) async {
    if (shiftModel != null) {
      final locationRef = _contextService.selectedCompanyLocation?.ref;
      this.companyRef = _contextService.selectedCompany.ref;
      if (locationRef != null && companyRef != null) {
        var workingHoursTr = await _workingHoursService.getWorkingHoursForCompany(locationRef);
        workingHoursList = workingHoursTr.map((element) => element.data).toList();
        final mappedWorkAreaOptions =
            workAreasList.map((element) => new FirestoreSelectOption(element.selfRef, element.data.workAreaName));
        workAreaOptions = SelectionOptions.fromList(mappedWorkAreaOptions.toList());
        if (mappedWorkAreaOptions.isNotEmpty) {
          final firstOption = mappedWorkAreaOptions.first;
          if (shiftModel.selectedWorkArea.isEmpty) {
            shiftModel.selectedWorkArea.select(firstOption);
          }
        }
      }
    }
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) {
    return Future.value(false);
  }
}
