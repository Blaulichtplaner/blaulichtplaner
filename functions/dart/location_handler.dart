import 'dart:async';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

import 'abstract_http_handler.dart';

class LocationHandler extends RequestHttpHandler {
  LocationHandler(App app) : super(app);

  @override
  Future<String> performPostAction(Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final locationName = data["locationName"];
    final parentRef = body["parentRef"];
    if (userId != null && locationName != null) {
      DocumentData locationData = DocumentData();
      locationData.setString("locationName", locationName);
      locationData.setDateTime("created", currentDate);
      final locationRef = await firestore.document(parentRef).collection("locations").add(locationData);
      DocumentData userToLocation = DocumentData();
      userToLocation.setString("role", "manager");
      userToLocation.setString("label", locationName);
      userToLocation.setString("type", "location");
      userToLocation.setDateTime("created", currentDate);
      userToLocation.setReference("reference", locationRef);
      await usersCollection
          .document(userId)
          .collection("roles")
          .document(locationRef.documentID)
          .setData(userToLocation);
      DocumentData locationToUser = DocumentData();
      locationToUser.setString("role", "manager");
      await locationRef.collection("users").document(userId).setData(locationToUser);
      return locationRef.documentID;
    } else {
      throw Exception("userId [${userId}] or locationName [${locationName}] is null");
    }
  }

  @override
  performPutAction(String selfRef, Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final data = body["data"];
    final locationName = data["locationName"];
    final locationSnapshot = await firestore.document(selfRef).get();
    if (locationSnapshot.exists) {
      UpdateData updateData = UpdateData();
      updateData.setString("locationName", locationName);
      await locationSnapshot.reference.updateData(updateData);

      final usersQuery = await locationSnapshot.reference.collection("users").get();
      final usersRef = app.firestore().collection("/users");
      UpdateData locationNameRefUpdate = UpdateData();
      locationNameRefUpdate.setString("label", locationName);
      List<Future<void>> updateRefFutures = [];
      usersQuery.documents.forEach((doc) {
        String refUserId = doc.documentID;
        updateRefFutures.add(usersRef
            .document(refUserId)
            .collection("roles")
            .document(locationSnapshot.documentID)
            .updateData(locationNameRefUpdate));
      });
      return Future.wait(updateRefFutures);
    } else {
      throw Exception("no loc with id ${selfRef}");
    }
  }
}
