import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';

export 'package:firebase/firestore.dart';

@Injectable()
class FirebaseService {
  final Firestore firestore;

  FirebaseService() : firestore = fb.firestore() {}

  companyReference(String companyId) {
    return firestore.doc("/companies/${companyId}");
  }

  locationReference(String companyId, String locationId) {
    return firestore.doc("/companies/${companyId}/locations/${locationId}");
  }

  workAreaReference(String companyId, String locationId, String workAreaId) {
    return firestore.doc("/companies/${companyId}/locations/${locationId}/workAreas/${workAreaId}");
  }

  Future<DocumentReference> saveShiftplan(DocumentReference companyRef, Shiftplan shiftplan) {
    return companyRef.collection("shiftplans").add(shiftplan.toMap());
  }

  Future<DocumentSnapshot> loadShiftplan(String shiftplanPath) {
    return firestore.doc(shiftplanPath).get();
  }

  Future<QuerySnapshot> selectShiftplans(DocumentReference companyRef, DocumentReference locationRef,
      {bool onlyPublic = false, DateTime maxFromDate}) {
    Query query = companyRef.collection("shiftplans");
    query = query.where("locationRef", "==", locationRef);
    if (onlyPublic) {
      query = query.where("status", "==", "public");
    }
    if (maxFromDate != null) {
      query = query.where("from", "<=", maxFromDate);
    }
    return query.get();
  }

  saveLastSelected(String userId, DocumentReference companyRef, DocumentReference locationRef) {
    return firestore.doc("users/${userId}").update(data: {
      "lastSelected": {"companyRef": companyRef, "locationRef": locationRef}
    });
  }

  Future<DocumentSnapshot> loadUser(String userId) {
    return firestore.doc("users/${userId}").get();
  }
}
