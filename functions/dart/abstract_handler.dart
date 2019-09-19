import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

abstract class RequestHandler {
  final App app;
  final CollectionReference usersCollection;
  final CollectionReference apiResult;

  RequestHandler(this.app)
      : usersCollection = app.firestore().collection("/users"),
        apiResult = app.firestore().collection("/apiResult");

  _filterUnknownProperties(Map<String, dynamic> data, List<String> knownFields) {
    return Map.fromEntries(
        data.entries.where((element) => knownFields.contains(element.key)));
  }

  performAction(DocumentData data, String userId, DateTime currentDate);

  handleRequest(DocumentSnapshot snapshot, EventContext eventContext) async {
    final createdDate = DateTime.now();

    final snapshotId = snapshot.documentID;
    final data = snapshot.data;
    final userId = data.getString("uid");

    DocumentData requestData = DocumentData();
    requestData.setDateTime("started", createdDate);
    requestData.setString("status", "running");
    final requestDocRef =
        apiResult.document(userId).collection("requests").document(snapshotId);
    await requestDocRef.setData(requestData);

    await performAction(data, userId, createdDate);

    await snapshot.reference.delete();
    requestData.setDateTime("finished", DateTime.now());
    requestData.setString("status", "finished");
    await requestDocRef.setData(requestData);
  }

  handler() {
    return (DocumentSnapshot snapshot, EventContext eventContext) async {
      return handleRequest(snapshot, eventContext);
    };
  }
}
