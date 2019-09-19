import 'dart:async';

import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';

class ShiftAssignmentService {
  final FirebaseService _firebaseService;

  ShiftAssignmentService(this._firebaseService);

  updateAssignments(ShiftModel shift, DocumentReference shiftplanRef, Iterable<EmployeePath> assignedEmployees) async {
    final firestore = _firebaseService.firestore;
    final assignmentsRef = firestore.collection("assignments");

    final Map<SelectablePath, DocumentReference> toUpdate = {};
    final List<Future> changeFutures = [];

    final querySnapshot = await assignmentsRef.where("shiftRef", "==", shift.shiftRef).get();
    querySnapshot.forEach((doc) {
      DocumentReference employeeRef = doc.get("employeeRef");
      // TODO check if we can use assignmentRef here
      EmployeePath option =
          assignedEmployees.firstWhere((option) => option.path == employeeRef.path, orElse: () => null);
      if (option != null) {
        toUpdate[option] = doc.ref;
      } else {
        changeFutures.add(doc.ref.delete());
      }
    });

    final workArea = shift.selectedWorkArea.selectedValues.first;

    for (EmployeePath employee in assignedEmployees) {
      DocumentReference knownRef = toUpdate[employee];
      Map<String, dynamic> assignmentData = {};
      if (knownRef != null) {
        assignmentData["updated"] = DateTime.now();
      } else {
        assignmentData["created"] = DateTime.now();
        assignmentData["shiftRef"] = shift.shiftRef;
        assignmentData["shiftplanRef"] = shiftplanRef;
        assignmentData["employeeRef"] = firestore.doc(employee.path);
        assignmentData["evaluated"] = false;
      }
      assignmentData["employeeLabel"] = employee.uiDisplayName;
      assignmentData["from"] = shift.from;
      assignmentData["to"] = shift.to;
      assignmentData["workAreaRef"] = firestore.doc(workArea.path);
      assignmentData["workAreaLabel"] = workArea.uiDisplayName;
      assignmentData["publicNote"] = shift.publicNote;
      assignmentData["locationLabel"] = shift.locationLabel;
      assignmentData["locationRef"] = shift.locationRef;
      assignmentData["status"] = shift.status;

      if (knownRef != null) {
        changeFutures.add(knownRef.update(data: assignmentData));
      } else {
        changeFutures.add(assignmentsRef.add(assignmentData));
      }
    }
    return changeFutures;
  }

  Future<List<Future<Null>>> deleteAssignments(DocumentReference shiftRef) async {
    final assignmentsRef = _firebaseService.firestore.collection("assignments");
    final futures = <Future<Null>>[];
    final querySnapshot = await assignmentsRef.where("shiftRef", "==", shiftRef).get();
    querySnapshot.forEach((doc) {
      futures.add(doc.ref.delete());
    });
    return futures;
  }
}
