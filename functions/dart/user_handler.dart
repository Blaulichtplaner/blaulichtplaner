import 'dart:async';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

import 'abstract_http_handler.dart';

class UserHandler extends RequestHttpHandler {
  UserHandler(App app) : super(app);

  @override
  performPutAction(String selfRef, Map<String, dynamic> body, String userId, DateTime currentDate) async {}

  @override
  Future<String> performPostAction(Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final regRef = firestore.collection("registrations").document(userId);
    final regSnapshot = await regRef.get();
    if (regSnapshot.exists) {
      final regData = regSnapshot.data;
      final role = regData.getString("role");
      final token = regData.getString("token");
      final data = body["data"];
      final givenToken = data["token"];

      if (role == null) {
        if (token == givenToken) {
          DocumentData docData = DocumentData();
          docData.setString("role", "user");
          docData.setString("firstName", regData.getString("firstName"));
          docData.setString("lastName", regData.getString("lastName"));
          docData.setString("email", regData.getString("email"));
          docData.setDateTime("privacyPolicyAccepted", regData.getDateTime("privacyPolicyAccepted"));
          docData.setDateTime("termsAccepted", regData.getDateTime("termsAccepted"));
          final userRef = firestore.collection("users").document(userId);
          await userRef.setData(docData);
          return userRef.path;
        } else {
          throw Exception("Invalid tokens: $givenToken != $token");
        }
      } else {
        throw Exception("User already has a role");
      }
    } else {
      throw Exception("User does not exist");
    }
  }
}
