import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:blaulichtplaner/src/domain/datetime_utils.dart';
import 'package:firebase/firestore.dart';

class Shift {
  DocumentReference shiftplanRef;
  DocumentReference shiftRef;
  DateTime from;
  DateTime to;
  String publicNote;
  String locationLabel;
  DocumentReference locationRef;
  DocumentReference workAreaRef;
  String workAreaLabel;
  String durationLabel;
  Role role;

  Shift.fromSnapshot(DocumentSnapshot snapshot, Role role) {
    shiftRef = snapshot.ref;
    shiftplanRef = snapshot.get("shiftplanRef");
    from = snapshot.get("from");
    to = snapshot.get("to");
    publicNote = snapshot.get("publicNote");
    locationLabel = snapshot.get("locationLabel");
    locationRef = snapshot.get("locationRef");
    workAreaRef = snapshot.get("wordAreaRef");
    workAreaLabel = snapshot.get("workAreaLabel");
    durationLabel = shiftDurationLabel(from, to);
    this.role = role;
  }
}

class Vote {
  bool isBid;
  DateTime from;
  DateTime to;
  DocumentReference shiftplanRef;
  DocumentReference shiftRef;
  DocumentReference employeeRef;
  String employeeLabel;
  DocumentReference selfRef;

  Vote.fromShift(Shift shift, bool isBid, DocumentReference employeeRef, String employeeLabel) {
    shiftplanRef = shift.shiftplanRef;
    shiftRef = shift.shiftRef;
    this.employeeRef = employeeRef;
    this.employeeLabel = employeeLabel;
    from = shift.from;
    to = shift.to;
    this.isBid = isBid;
  }

  Vote.fromSnapshot(DocumentSnapshot document) {
    selfRef = document.ref;
    shiftplanRef = document.get("shiftplanRef");
    shiftRef = document.get("shiftRef");
    employeeRef = document.get("employeeRef");
    employeeLabel = document.get("employeeLabel");
    from = document.get("from");
    to = document.get("to");
    isBid = document.get("isBid");
  }
}
