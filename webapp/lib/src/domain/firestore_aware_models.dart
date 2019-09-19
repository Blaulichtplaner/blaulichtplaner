import 'package:angular_components/model/ui/display_name.dart';
import 'package:firebase/firestore.dart';

class WorkAreaAssignment {
  DocumentReference workAreaRef;

  WorkAreaAssignment(this.workAreaRef);

  WorkAreaAssignment.fromMap(Map<String, dynamic> mapData) {
    this.workAreaRef = mapData["workAreaRef"];
  }
}

class Shiftplan implements HasUIDisplayName {
  DocumentReference selfRef;
  DateTime from;
  DateTime to;
  String label;
  DocumentReference locationRef;
  String locationLabel;
  String status;

  static String STATUS_PLANNING = "planning";
  static String STATUS_PUBLIC = "public";
  
  static List<String> statusOptions = [STATUS_PLANNING, STATUS_PUBLIC];
  static List<String> statusLabels = ["Planung", "Öffentlich"];

  static String defaultStatusOption() => statusOptions[0];

  Shiftplan(this.from, this.to, this.label, this.status, this.locationRef, this.locationLabel);

  Shiftplan.fromSnapshot(DocumentSnapshot snapshot) {
    this.selfRef = snapshot.ref;
    this.from = snapshot.get("from");
    this.to = snapshot.get("to");
    this.label = snapshot.get("label");
    this.status = snapshot.get("status");
    this.locationRef = snapshot.get("locationRef");
    this.locationLabel = snapshot.get("locationLabel");
  }

  bool isPlanning() {
    return status == "planning";
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result["from"] = from;
    result["to"] = to;
    result["label"] = label;
    result["status"] = status;
    result["locationRef"] = locationRef;
    result["locationLabel"] = locationLabel;
    return result;
  }

  @override
  String get uiDisplayName {
    if (status != null) {
      return label + " (" + statusLabels[statusOptions.indexOf(status)] + ")";
    } else {
      return label;
    }
  }
}

class TransportResult<T> {
  DocumentReference selfRef;
  T data;

  String get selfPath => selfRef.path;

  String get id => selfRef.id;

  TransportResult(this.selfRef, this.data);
}

class FirestoreSelectOption implements HasUIDisplayName {
  final DocumentReference ref;
  final String label;

  String get path => ref.path;

  FirestoreSelectOption(this.ref, this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreSelectOption && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String get uiDisplayName => label;
}
