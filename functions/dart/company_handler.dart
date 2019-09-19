import 'dart:async';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

import 'abstract_http_handler.dart';

class CompanyHandler extends RequestHttpHandler {
  
  CompanyHandler(App app) : super(app);

  @override
  Future<String> performPostAction(
      Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final companyName = data["companyName"];
    print("auth [${userId}] or companyName [${companyName}]");
    if (userId != null && companyName != null) {
      DocumentData companyData = DocumentData();
      companyData.setString("companyName", companyName);
      companyData.setDateTime("created", currentDate);
      final compRef = await firestore.collection("companies").add(companyData);
      DocumentData userToCompany = DocumentData();
      userToCompany.setString("role", "manager");
      userToCompany.setString("label", companyName);
      userToCompany.setString("type", "company");
      userToCompany.setDateTime("created", currentDate);
      userToCompany.setReference("reference", compRef);
      await usersCollection
          .document(userId)
          .collection("roles")
          .document(compRef.documentID)
          .setData(userToCompany);
      DocumentData companyToUser = DocumentData();
      companyToUser.setString("role", "manager");
      await compRef.collection("users").document(userId).setData(companyToUser);
      return compRef.documentID;
    } else {
      throw Exception("userId [${userId}] or companyName [${companyName}] is null");
    }
  }

  @override
  performPutAction(String selfRef, Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final companyName = data["companyName"];
    final companySnapshot = await firestore.document(selfRef).get();
    if (companySnapshot.exists) {
      UpdateData updateData = UpdateData();
      updateData.setString("companyName", companyName);
      await companySnapshot.reference.updateData(updateData);

      final usersQuery =
          await companySnapshot.reference.collection("users").get();
      final usersRef = app.firestore().collection("/users");
      UpdateData companyNameRefUpdate = UpdateData();
      companyNameRefUpdate.setString("label", companyName);
      List<Future<void>> updateRefFutures = [];
      usersQuery.documents.forEach((doc) {
        String refUserId = doc.documentID;
        updateRefFutures.add(usersRef
            .document(refUserId)
            .collection("roles")
            .document(companySnapshot.documentID)
            .updateData(companyNameRefUpdate));
      });
      return Future.wait(updateRefFutures);
    } else {
      print("no company with id ${selfRef}");
      return null;
    }
  }
}
