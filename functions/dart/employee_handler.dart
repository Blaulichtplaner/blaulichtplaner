import 'dart:async';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

import 'abstract_http_handler.dart';

class EmployeeHandler extends RequestHttpHandler {
  EmployeeHandler(App app) : super(app);

  updateAssignments(DocumentReference parentRef, DocumentReference employeeRef, List<String> workAreaRefs) async {
    final snapshot =
        await parentRef.collection("workAreaAssignments").where("employeeRef", isEqualTo: employeeRef).get();
    final deleteAndWriteFutures = <Future>[];
    List<String> workAreaAssignments = workAreaRefs ?? [];
    if (snapshot.isNotEmpty) {
      final docs = snapshot.documents;
      docs.forEach((DocumentSnapshot doc) {
        if (workAreaAssignments.contains(doc.reference.path)) {
          workAreaAssignments.remove(doc.reference.path);
        } else {
          deleteAndWriteFutures.add(doc.reference.delete());
        }
      });
    }
    
    workAreaAssignments.forEach((element) {
      DocumentData data = DocumentData();
      data.setReference("employeeRef", employeeRef);
      data.setReference("workAreaRef", firestore.document(element));
      deleteAndWriteFutures.add(parentRef.collection("workAreaAssignments").add(data));
    });
    return Future.wait(deleteAndWriteFutures);
  }

  deleteReferences(DocumentReference parentRef, DocumentReference employeeRef) async {
    final snapshot =
        await parentRef.collection("workAreaAssignments").where("employeeRef", isEqualTo: employeeRef).get();
    final deleteAndWriteFutures = <Future>[];
    if (snapshot.isNotEmpty) {
      snapshot.documents.forEach((doc) {
        deleteAndWriteFutures.add(doc.reference.delete());
      });
    }
    return Future.wait(deleteAndWriteFutures);
  }

  List<String> _toStringList(Iterable iter) {
    List<String> result = [];
    for (int i = 0; i < iter.length; i++) {
      result.add(iter.elementAt(i) as String);
    }
    return result;
  }

  @override
  Future<String> performPostAction(Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final firstName = data["firstName"];
    final lastName = data["lastName"];
    final parentRef = body["parentRef"];
    if (userId != null && firstName != null) {
      DocumentData insertData = DocumentData();
      insertData.setString("firstName", firstName);
      insertData.setString("lastName", lastName);
      insertData.setDateTime("created", currentDate);
      final employeeRef = await firestore.document(parentRef).collection("employees").add(insertData);
      // TODO check this fix in future releases
      // https://github.com/pulyaevskiy/firebase-functions-interop/issues/28
      List<String> assignments = _toStringList(data["workAreaAssignments"]);
      await updateAssignments(firestore.document(parentRef), employeeRef, assignments);
      return employeeRef.documentID;
    } else {
      throw Exception("userId [${userId}] or firstName [${firstName}] is null");
    }
  }

  @override
  performPutAction(String selfRef, Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final firstName = data["firstName"];
    final lastName = data["lastName"];
    final parentRef = body["parentRef"];
    final employeeRef = firestore.document(selfRef);
    final snapshot = await employeeRef.get();
    if (snapshot.exists) {
      UpdateData updateData = UpdateData();
      updateData.setString("firstName", firstName);
      updateData.setString("lastName", lastName);
      // TODO check this fix in future releases
      List<String> assignments = _toStringList(data["workAreaAssignments"]);
      await updateAssignments(firestore.document(parentRef), employeeRef, assignments);
      return snapshot.reference.updateData(updateData);
    } else {
      throw Exception("no obj with id ${selfRef}");
    }
  }

  performDeleteAction(String selfRef, String userId) async {
    final employeeRef = firestore.document(selfRef);
    final objectSnapshot = await employeeRef.get();
    if (objectSnapshot.exists) {
      // TODO  await deleteReferences(parentRef, employeeRef);
      // parentRef is missing. find a solution
      return objectSnapshot.reference.delete();
    } else {
      print("no object with id ${selfRef}");
    }
  }
}
