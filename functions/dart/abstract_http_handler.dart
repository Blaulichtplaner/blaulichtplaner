import 'dart:async';
import 'dart:io';

import 'package:firebase_functions_interop/firebase_functions_interop.dart';

class NotFoundException implements Exception {}

class InternalException implements Exception {}

abstract class RequestHttpHandler {
  final App app;
  final Firestore firestore;
  final CollectionReference usersCollection;

  RequestHttpHandler(this.app)
      : firestore = app.firestore(),
        usersCollection = app.firestore().collection("users");

  Future<String> performPostAction(
      Map<String, dynamic> body, String userId, DateTime currentDate) {
    throw Exception("not implemented");
  }

  performPutAction(String id, Map<String, dynamic> body, String userId,
      DateTime currentDate) {
    throw Exception("not implemented");
  }

  performDeleteAction(String selfRef, String userId) async {
    final objectSnapshot = await firestore.document(selfRef).get();
    if (objectSnapshot.exists) {
      await objectSnapshot.reference.delete();
      final usersQuery =
          await objectSnapshot.reference.collection("users").get();
      final usersRef = app.firestore().collection("/users");
      List<Future<void>> deleteRefFutures = [];
      usersQuery.documents.forEach((doc) {
        String refUserId = doc.documentID;
        deleteRefFutures.add(usersRef
            .document(refUserId)
            .collection("roles")
            .document(objectSnapshot.documentID)
            .delete());
        deleteRefFutures.add(doc.reference.delete());
      });
      return Future.wait(deleteRefFutures);
    } else {
      print("no object with id ${selfRef}");
    }
  }

  addOriginHeaders(HttpHeaders headers, origin) {
    if (origin != null) {
      headers
        ..set("Access-Control-Allow-Origin", origin)
        ..set("Access-Control-Allow-Methods", "POST,PUT,DELETE,OPTIONS")
        ..set("Access-Control-Allow-Headers", "Content-Type,Authorization")
        ..set("Access-Control-Expose-Headers", "Location")
        ..set("Access-Control-Allow-Credentials", true);
    }
  }

  handleRequest(ExpressHttpRequest request) async {
    if (request.method == "OPTIONS") {
      addOriginHeaders(
          request.response.headers, request.headers.value("origin"));
      request.response
        ..statusCode = 200
        ..close();
    } else {
      final currentDate = DateTime.now();
      final userId = request.headers.value("Authorization");
      if (userId == null) {
        request.response
          ..statusCode = 403
          ..close();
      } else {
        final response = request.response;
        addOriginHeaders(response.headers, request.headers.value("origin"));

        if (request.method == "POST") {
          final data = request.body;
          try {
            final refId = await performPostAction(data, userId, currentDate);
            response.headers.set("location", refId);
            response
              ..statusCode = 201
              ..close();
          } on InternalException {
            response
              ..statusCode = 500
              ..close();
          } catch (e) {
            print(e);

            response
              ..statusCode = 400
              ..write(e.toString())
              ..close();
          }
        } else if (request.method == "PUT") {
          String selfRef = request.uri.pathSegments.last;
          final data = request.body;
          try {
            await performPutAction(
                Uri.decodeComponent(selfRef), data, userId, currentDate);
            response
              ..statusCode = 200
              ..close();
          } on NotFoundException {
            response
              ..statusCode = 400
              ..close();
          } on InternalException {
            response
              ..statusCode = 500
              ..close();
          }
        } else if (request.method == "DELETE") {
          String selfRef = request.uri.pathSegments.last;
          await performDeleteAction(Uri.decodeComponent(selfRef), userId);
          response
            ..statusCode = 200
            ..close();
        }
      }
    }
  }

  handler() {
    return (ExpressHttpRequest request) async {
      return handleRequest(request);
    };
  }
}
