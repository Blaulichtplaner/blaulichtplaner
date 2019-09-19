import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/evaluation/assignment_editor_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/widgets/pipes.dart';
import 'package:blaulichtplaner/src/utils/components_utils.dart';

@Component(selector: 'blp-evaluation-form', templateUrl: 'evaluation_form_component.html', directives: [
  materialDirectives,
  coreDirectives,
  routerDirectives,
  formDirectives,
  AssignmentEditorComponent,
  DateTimePickerValueAccessor
], providers: [
  materialProviders,
], pipes: [
  DurationPipe
])
class EvaluationFormComponent implements DoCheck {
  @Input("shift")
  Shift shift;
  @Input("evaluation")
  Evaluation evaluation;

  int actualDuration;
  int plannedDuration;
  String reasonOvertime;

  void _updateContent() {
    if (shift != null && evaluation != null) {
      plannedDuration = shift.to.difference(shift.from).inMinutes;
      if (evaluation.actualTo != null) {
        actualDuration = evaluation.actualTo.difference(evaluation.actualFrom).inMinutes;
      }
      if (evaluation.reasonOvertime != null && evaluation.reasonOvertime > 0) {
        switch (evaluation.reasonOvertime) {
          case 1:
            reasonOvertime = "Einsatz";
            break;
          case 2:
            reasonOvertime = "Nachfolger verspätet";
            break;
          case 99:
            reasonOvertime = "Anderer Grund";
            break;
          default:
        }
      }
    }
  }

  @override
  void ngDoCheck() {
    _updateContent();
  }
}
