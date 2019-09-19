import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';

@Component(selector: 'blp-assignment-editor', templateUrl: 'assignment_editor_component.html', directives: [
  coreDirectives,
  MaterialButtonComponent,
  MaterialIconComponent,
  materialInputDirectives,
  formDirectives
])
class AssignmentEditorComponent {
  @Input("tasks")
  List<AssignmentTask> tasks;

  String assignmentNumber;

  addTask() {
    if (assignmentNumber != null && assignmentNumber.isNotEmpty) {
      tasks.add(AssignmentTask(assignmentNumber));
      assignmentNumber = null;
    }
  }

  deleteTask(AssignmentTask task) {
    tasks.remove(task);
  }
}
