import 'dart:async';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

import 'abstract_http_handler.dart';

class WorkAreaHandler extends RequestHttpHandler {
  WorkAreaHandler(App app) : super(app);

  @override
  Future<String> performPostAction(Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final workAreaName = data["workAreaName"];
    final parentRef = body["parentRef"];
    if (userId != null && workAreaName != null) {
      DocumentData workAreaData = DocumentData();
      workAreaData.setString("workAreaName", workAreaName);
      workAreaData.setString("color", data["color"]);
      workAreaData.setDateTime("created", currentDate);
      final workAreaRef = await firestore.document(parentRef).collection("workAreas").add(workAreaData);
      DocumentData userToWorkArea = DocumentData();
      userToWorkArea.setString("role", "manager");
      userToWorkArea.setString("label", workAreaName);
      userToWorkArea.setString("type", "workArea");
      userToWorkArea.setDateTime("created", currentDate);
      userToWorkArea.setReference("reference", workAreaRef);
      await usersCollection
          .document(userId)
          .collection("roles")
          .document(workAreaRef.documentID)
          .setData(userToWorkArea);
      DocumentData workAreaToUser = DocumentData();
      workAreaToUser.setString("role", "manager");
      await workAreaRef.collection("users").document(userId).setData(workAreaToUser);
      return workAreaRef.documentID;
    } else {
      throw Exception("userId [${userId}] or workAreaName [${workAreaName}] is null");
    }
  }

  @override
  performPutAction(String selfRef, Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final workAreaName = data["workAreaName"];
    final workAreaSnapshot = await firestore.document(selfRef).get();
    if (workAreaSnapshot.exists) {
      UpdateData updateData = UpdateData();
      updateData.setString("workAreaName", workAreaName);
      updateData.setString("color", data["color"]);
      await workAreaSnapshot.reference.updateData(updateData);
      final usersQuery = await workAreaSnapshot.reference.collection("users").get();
      final usersRef = app.firestore().collection("/users");
      UpdateData workAreaNameRefUpdate = UpdateData();
      workAreaNameRefUpdate.setString("label", workAreaName);
      List<Future<void>> updateRefFutures = [];
      usersQuery.documents.forEach((doc) {
        String refUserId = doc.documentID;
        updateRefFutures.add(usersRef
            .document(refUserId)
            .collection("roles")
            .document(workAreaSnapshot.documentID)
            .updateData(workAreaNameRefUpdate));
      });
      return Future.wait(updateRefFutures);
    } else {
      throw Exception("no loc with id ${selfRef}");
    }
  }
}
