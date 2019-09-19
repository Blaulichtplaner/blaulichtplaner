import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart' as models;

@Pipe('employeeName')
class EmployeeNamePipe extends PipeTransform {
  transform(dynamic value) {
    if (value is models.Employee) {
      return value.uiDisplayName;
    } else {
      return value;
    }
  }
}
