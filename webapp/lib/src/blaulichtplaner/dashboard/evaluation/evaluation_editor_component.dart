import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/evaluation/evaluation_form_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/evaluation/evaluation_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/utils/components_utils.dart';

@Component(selector: 'blp-evaluation-editor', templateUrl: 'evaluation_editor_component.html', styleUrls: [
  'evaluation_editor_component.css'
], directives: [
  materialDirectives,
  coreDirectives,
  routerDirectives,
  formDirectives,
  EvaluationFormComponent,
  DeferredContentDirective,
  DateTimePickerValueAccessor
], providers: [
  materialProviders,
  ClassProvider(EvaluationService)
], pipes: [
  DatePipe
])
class EvaluationEditorComponent {
  Shift _shift;
  final FirebaseService _firebaseService;
  final EvaluationService _evaluationService;

  DateTime minDateTime;
  DateTime maxDateTime;

  List<AssignmentEvaluation> evaluations = [];

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
    _shift = value;
    if (_shift.hasAssignments()) {
      evaluations = _shift.getAssignedEmployees()
          .map((assignment) => AssignmentEvaluation(assignment.ref, assignment.label, assignment.assignmentRef))
          .toList();
      evaluations.first.expanded = true;
    }
  }

  Shift get shift => _shift;

  EvaluationEditorComponent(this._firebaseService, this._evaluationService);

  final _cancel = new StreamController<Null>();

  @Output()
  Stream<ShiftDay> get onCancel => _cancel.stream;

  finishEditing() {
    _cancel.add(null);
  }

  reject(AssignmentEvaluation assignmentEvaluation) async {
    await _evaluationService.reject(assignmentEvaluation);
    assignmentEvaluation.expanded = false;
    finishEditingIfOnlyEvaluation();
  }

  confirm(AssignmentEvaluation assignmentEvaluation) async {
    await _evaluationService.confirm(assignmentEvaluation, shift);
    assignmentEvaluation.expanded = false;
    finishEditingIfOnlyEvaluation();
  }

  void finishEditingIfOnlyEvaluation() {
    if (evaluations.length == 1) {
      finishEditing();
    }
  }

  usePlannedWorktimes(AssignmentEvaluation assignmentEvaluation) {
    assignmentEvaluation.evaluation.actualFrom = _shift.from;
    assignmentEvaluation.evaluation.actualTo = _shift.to;
  }

  requestEvaluation(AssignmentEvaluation assignmentEvaluation) {
    // TODO Issue #27
  }

  Future<bool> updateEvaluation(AssignmentEvaluation assignmentEvaluation) async {
    assignmentEvaluation.loading = true;

    final evaluationQuery = await _firebaseService.firestore
        .collection("evaluations")
        .where("shiftRef", "==", _shift.shiftRef)
        .where("employeeRef", "==", assignmentEvaluation.ref)
        .get();

    Evaluation evaluation = assignmentEvaluation.evaluation;
    if (!evaluationQuery.empty) {
      evaluation.updateWithSnapshot(evaluationQuery.docs.first);
    } else {
      evaluation.shiftRef = _shift.shiftRef;
      evaluation.shiftplanRef = _shift.shiftplanRef;
    }

    assignmentEvaluation.loading = false;
    return true;
  }
}
