import 'dart:async';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

import 'abstract_http_handler.dart';
import 'mail_service.dart';

class KeyValue {
  String key;
  String value;

  KeyValue(this.key, this.value);
}

class InvitationHandler extends RequestHttpHandler {
  String _basicAuth;

  InvitationHandler(App app) : super(app) {
    _basicAuth = FirebaseFunctions.config.get("mailgun.basicauth");
    if (_basicAuth == null) {
      print("Basic auth param missing!!");
    }
  }

  /*
    create invitation for the employeeId, all currently selected workAreas, and the location
   */
  Future<List<DocumentReference>> _getWorkAreasForEmployee(
      DocumentReference locationRef, DocumentReference employeeRef) async {
    print("searching for workareaassignments: ${locationRef.path}");
    print("employee: ${employeeRef.path}");

    final querySnapshot = await locationRef
        .collection("workAreaAssignments")
        .where("employeeRef", isEqualTo: employeeRef)
        .get();
    if (querySnapshot.isNotEmpty) {
      return querySnapshot.documents
          .map((snapshot) => snapshot.data.getReference("workAreaRef"))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<String> performPostAction(
      Map<String, dynamic> body, String userId, DateTime currentDate) async {
    final contentData = body["data"];
    final employeePath = contentData["employeePath"];
    final locationPath = contentData["locationPath"];
    final email = contentData["email"];
    if (userId != null && email != null) {
      final employeeRef = firestore.document(employeePath);
      final locationRef = firestore.document(locationPath);
      final companyPath = locationPath.split('/')[1];
      final companyRef = firestore.document('companies/$companyPath');

      DocumentSnapshot locationSnapshot = await locationRef.get();
      DocumentSnapshot companySnapshot = await companyRef.get();
      if (locationSnapshot.exists && companySnapshot.exists) {
        String locationLabel = locationSnapshot.data.getString("locationName");
        String companyLabel = companySnapshot.data.getString("companyName");

        DocumentData data = DocumentData();
        data.setDateTime("created", currentDate);
        data.setString("invitationBy", userId);
        data.setString("email", email);
        data.setReference("employeeRef", employeeRef);
        data.setReference("locationRef", locationRef);
        data.setString("locationLabel", locationLabel);
        data.setReference("companyRef", companyRef);
        data.setString("companyLabel", companyLabel);
        List<DocumentReference> workAreas =
            await _getWorkAreasForEmployee(locationRef, employeeRef);
        print("workAreas ${workAreas}");

        data.setList("workAreas", workAreas);

        final reference = await firestore.collection("invitations").add(data);

        MailService mailService = MailService(_basicAuth);
        final mailSendResponse = await mailService.sendInvite(email,
            "https://blaulichtplaner.app/#invitation/" + reference.documentID);
        if (mailSendResponse.statusCode != 200) {
          print(mailSendResponse.body);

          await reference.delete();
          throw Exception(
              "Mail send failed with: ${mailSendResponse.statusCode}");
        } else {
          return "created";
        }
      } else {
        throw InternalException();
      }
    } else {
      throw Exception("userId [${userId}] or email [${email}] is null");
    }
  }

  Future<String> _createNameForReference(
      DocumentReference ref, String type) async {
    switch (type) {
      case "location":
        final doc = await ref.get();
        return doc.data.getString("locationName");
      case "employee":
        final doc = await ref.get();
        final firstName = doc.data.getString("firstName");
        final lastName = doc.data.getString("lastName");
        return firstName + " " + lastName;
      case "workArea":
        final doc = await ref.get();
        return doc.data.getString("workAreaName");
      default:
        throw Exception("unkown type");
    }
  }

  _addUserRole(CollectionReference rolesRef, DocumentReference ref, String type,
      String role, DocumentData data) async {
    final referenceQuery =
        await rolesRef.where("reference", isEqualTo: ref).get();
    if (referenceQuery.isEmpty) {
      DocumentReference locationRef = data.getReference("locationRef");
      String locationLabel = data.getString("locationLabel");
      DocumentReference companyRef = data.getReference("companyRef");
      String companyLabel = data.getString("companyLabel");
      final label = await _createNameForReference(ref, type);

      DocumentData roleData = DocumentData()
        ..setString("role", role)
        ..setString("type", type)
        ..setDateTime("created", DateTime.now())
        ..setReference("reference", ref)
        ..setString("label", label);

      if (type == "employee") {
        roleData
          ..setReference("locationRef", locationRef)
          ..setString("locationLabel", locationLabel)
          ..setReference("companyRef", companyRef)
          ..setString("companyLabel", companyLabel);
      }

      return rolesRef.add(roleData);
    } else {
      return null;
    }
  }

  @override
  performPutAction(String id, _, String userId, DateTime currentDate) async {
    DocumentReference invitationRef = firestore.document("/invitations/${id}");

    final invitationSnapshot = await invitationRef.get();
    if (invitationSnapshot.exists) {
      DocumentData data = invitationSnapshot.data;
      DocumentReference employeeRef = data.getReference("employeeRef");
      DocumentReference locationRef = data.getReference("locationRef");
      List<DocumentReference> workAreas = List.from(data.getList("workAreas"));
      print("WorkAreas: ${workAreas}");
      DocumentReference userRef = firestore.document("users/$userId");
      CollectionReference rolesRef = userRef.collection("roles");
      await _addUserRole(rolesRef, employeeRef, "employee", "user", data);
      await _addUserRole(rolesRef, locationRef, "location", "user", data);

      for (final workAreaRef in workAreas) {
        await _addUserRole(rolesRef, workAreaRef, "workArea", "user", data);
      }

      UpdateData updateData = UpdateData();
      updateData.setReference("userRef", userRef);
      await employeeRef.updateData(updateData);
      await invitationRef.delete();
    } else {
      throw NotFoundException();
    }
  }
}
