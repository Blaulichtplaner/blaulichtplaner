import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';

@Injectable()
class EvaluationService {
  final FirebaseService _firebaseService;

  EvaluationService(this._firebaseService);

  reject(AssignmentEvaluation assignmentEvaluation) async {
    Evaluation evaluation = assignmentEvaluation.evaluation;
    evaluation.actualFrom = null;
    evaluation.actualTo = null;
    evaluation.finished = false;
    evaluation.status = "rejected";
    await _saveEvaluation(evaluation);
  }

  confirm(AssignmentEvaluation assignmentEvaluation, Shift shift) async {
    Evaluation evaluation = assignmentEvaluation.evaluation;

    if (evaluation.actualFrom == null) {
      evaluation.actualFrom = shift.from;
    }
    if (evaluation.actualTo == null) {
      evaluation.actualTo = shift.to;
    }
    evaluation.finished = true;
    evaluation.status = "confirmed";

    await _saveEvaluation(evaluation);
  }

  Map<String, dynamic> _convertTask(AssignmentTask task) {
    Map<String, dynamic> data = {};
    data["reference"] = task.reference;
    data["remarks"] = task.remarks;
    data["taskTime"] = task.taskTime;
    data["type"] = task.type;
    return data;
  }

  _saveEvaluation(Evaluation evaluation) async {
    final evaluations = _firebaseService.firestore.collection("evaluations");
    Map<String, dynamic> data = {};

    if (evaluation.selfRef == null) {
      data["created"] = DateTime.now();
      data["shiftRef"] = evaluation.shiftRef;
      data["assignmentRef"] = evaluation.assignmentRef;
      data["shiftplanRef"] = evaluation.shiftplanRef;
      data["employeeRef"] = evaluation.employeeRef;
    }
    data["actualFrom"] = evaluation.actualFrom;
    data["actualTo"] = evaluation.actualTo;
    data["finished"] = evaluation.finished;
    data["status"] = evaluation.status;
    data["remarks"] = evaluation.remarks;
    // TODO fix this, create issue in firebase (problem only occurs if the null value is read from the database)
    data["managerRemarks"] = evaluation.managerRemarks == null ? null : evaluation.managerRemarks;
    data["didNotAppear"] = evaluation.didNotAppear == null ? false : evaluation.didNotAppear;
    data["tasks"] = evaluation.tasks.map(_convertTask).toList();

    if (evaluation.selfRef == null) {
      print("insert new evaluation");
      evaluation.selfRef = await evaluations.add(data);
    } else {
      print("save evaluation");
      await evaluation.selfRef.set(data, SetOptions(merge: true));
    }
  }
}
