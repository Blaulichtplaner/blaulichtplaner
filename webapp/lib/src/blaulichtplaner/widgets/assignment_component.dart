import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';

@Component(selector: 'blp-assignment', template: "<div>{{ task.reference }}</div>")
class AssignmentComponent {
  @Input("task")
  AssignmentTask task;
}
