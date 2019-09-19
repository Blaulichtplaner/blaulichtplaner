import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/model/ui/has_factory.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/assignments/assignment_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/availability_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/employee_select_component.template.dart'
    as uiTemplate;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_manager_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart' as models;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:firebase/firestore.dart';

@Component(selector: 'blp-selectable-employee', directives: [
  coreDirectives,
  MaterialIconComponent,
  MaterialSpinnerComponent
], template: r'''
        <div>{{employee.uiDisplayName}}</div>
        <material-spinner *ngIf="employee.checking"></material-spinner>
        <material-icon *ngIf="employee.status != null" [style.color]="employee.color" 
        size="medium" icon="event_{{ employee.status.status }}" 
        title="{{employee.status.description}}"></material-icon>
    ''', styles: [
  ':host { display: flex; align-items: center; }'
      'material-icon { margin-left:8px }'
      'material-spinner { margin-left:8px; width: 16px; height:16px }',
])
class SelectableEmployeeRendererComponent implements RendersValue<_SelectableEmployee> {
  _SelectableEmployee employee;

  @override
  set value(_SelectableEmployee newValue) {
    employee = newValue;
  }
}

class _SelectableEmployee implements EmployeePath, Comparable<_SelectableEmployee> {
  final String path;
  final String title;
  final String firstName;
  final String lastName;
  AvailabilityStatus status;
  bool checking = false;

  _SelectableEmployee(this.path, this.title, this.firstName, this.lastName);

  @override
  String get uiDisplayName =>
      title != null && title.isNotEmpty ? title + " " + firstName + " " + lastName : firstName + " " + lastName;

  String get color {
    if (status == null) {
      return "black";
    } else {
      switch (status.status) {
        case "available":
          return "green";
        case "busy":
          return "red";
        case "node":
          return "orange";
        default:
          return "black";
      }
    }
  }

  @override
  int compareTo(_SelectableEmployee other) {
    int c = lastName.compareTo(other.lastName);
    if (c == 0) {
      c = firstName.compareTo(other.firstName);
      if (c == 0) {
        c = path.compareTo(other.path);
      }
    }
    return c;
  }

  @override
  bool operator ==(Object other) => other is EmployeePath && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

@Component(selector: 'blp-employee-select', templateUrl: 'employee_select_component.html', directives: [
  materialDirectives,
  coreDirectives,
  routerDirectives,
], providers: [
  materialProviders,
  ClassProvider(EmployeeManagerService),
  ClassProvider(AssignmentService),
], pipes: [
  DatePipe
])
class EmployeeSelectComponent implements OnInit, OnDestroy, OnChanges {
  final EmployeeManagerService _employeeManagerService;
  final FirebaseService _firebaseService;
  final AvailabilityService _availabilityService = AvailabilityService();
  final AssignmentService _assignmentService;

  final _employeeOptions = <_SelectableEmployee>[];

  FactoryRenderer get selectableEmployeeRenderer => (_) => uiTemplate.SelectableEmployeeRendererComponentNgFactory;

  String searchQuery = "";

  @Input("companyRef")
  DocumentReference companyRef;

  @Input("shift")
  ShiftModel shiftModel;

  @Input("assignedEmployees")
  SelectionModel<EmployeePath> assignedEmployees;

  SelectionOptions<_SelectableEmployee> possibleEmployees = SelectionOptions.fromList([]);

  @ViewChild("searchInput")
  MaterialInputComponent searchInput;

  StreamSubscription keyPressSubscription = null;
  StreamSubscription<List<SelectionChangeRecord<EmployeePath>>> selectionChangeSubscription = null;

  EmployeeSelectComponent(this._employeeManagerService, this._firebaseService, this._assignmentService);

  @override
  void ngOnInit() {
    keyPressSubscription = searchInput.onKeypress.listen(_searchPossibleEmployees);
    selectionChangeSubscription = assignedEmployees.selectionChanges.listen(_verifyAvailability);
  }

  @override
  void ngOnDestroy() {
    keyPressSubscription?.cancel();
    selectionChangeSubscription?.cancel();
  }

  void _verifyAvailability(List<SelectionChangeRecord<EmployeePath>> selectionChanges) {
    for (SelectionChangeRecord<EmployeePath> change in selectionChanges) {
      for (EmployeePath addedEmployee in change.added) {
        _checkEmployeeAvailability(addedEmployee);
      }
    }
  }

  _checkEmployeeAvailability(EmployeePath selectable) async {
    _SelectableEmployee employee =
        possibleEmployees.optionsList.firstWhere((element) => element.path == selectable.path);
    if (employee != null) {
      employee.checking = true;
      employee.status = null;
      SimpleDateRange rangeToCheck = SimpleDateRange(shiftModel.from, shiftModel.to, shiftModel.locationRef.path);
      DocumentReference employeeRef = _firebaseService.firestore.doc(employee.path);
      List<SimpleDateRange> employeeAvailability =
          await _assignmentService.getEmployeeAvailability(employeeRef, rangeToCheck);

      for (SimpleDateRange sdr in employeeAvailability) {
        print("${sdr.from} => ${sdr.to}");
      }

      print("Our range: ${rangeToCheck.from} => ${rangeToCheck.to}");

      final checkResult = _availabilityService.checkTimes(employeeAvailability, rangeToCheck);
      employee.status = checkResult;
      employee.checking = false;
    }
  }

  _searchPossibleEmployees(String query) {
    if (query == null || query.isEmpty) {
      possibleEmployees = SelectionOptions.fromList(_employeeOptions);
    } else {
      String lowerCaseQuery = query.toLowerCase();
      List<_SelectableEmployee> filteredEmployees = _employeeOptions.where((element) {
        bool nameMatches = element.firstName.toLowerCase().contains(lowerCaseQuery) ||
            element.lastName.toLowerCase().contains(lowerCaseQuery);
        bool alreadySelected = assignedEmployees.isSelected(element);
        return nameMatches || alreadySelected;
      }).toList();
      possibleEmployees = SelectionOptions.fromList(filteredEmployees);
    }
  }

  _updatePossibleEmployees() async {
    if (companyRef != null) {
      _employeeOptions.clear();
      final List<TransportResult<models.Employee>> employeeList =
          await _employeeManagerService.getEmployees(companyRef.id);
      for (TransportResult<models.Employee> employeeTr in employeeList) {
        models.Employee employee = employeeTr.data;
        _employeeOptions
            .add(_SelectableEmployee(employeeTr.selfPath, employee.title, employee.firstName, employee.lastName));
      }
      _employeeOptions.sort();
      _searchPossibleEmployees(null);
    }
  }

  @override
  void ngOnChanges(Map<String, SimpleChange> changes) {
    bool updateNeeded = false;
    changes.forEach((key, change) {
      if (key == "companyRef") {
        updateNeeded = true;
      }
    });
    if (updateNeeded) {
      _updatePossibleEmployees();
    }
  }
}
