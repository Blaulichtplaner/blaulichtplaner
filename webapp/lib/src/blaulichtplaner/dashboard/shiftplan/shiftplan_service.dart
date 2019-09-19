import 'dart:async';

import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';

class ShiftplanService {
  static Future publishShiftplan(DocumentReference ref) async {
    final Firestore firestore = fb.firestore();
    final batch = firestore.batch();

    final updateData = <String, dynamic>{};
    updateData["status"] = Shiftplan.STATUS_PUBLIC;
    batch.update(ref, data: updateData);

    final shiftsQuery = await firestore.collection("shifts").where("shiftplanRef", "==", ref).get();
    for (final doc in shiftsQuery.docs) {
      batch.update(doc.ref, data: {"status": Shiftplan.STATUS_PUBLIC});
    }
    final assignmentsQuery = await firestore.collection("assignments").where("shiftplanRef", "==", ref).get();
    for (final doc in assignmentsQuery.docs) {
      batch.update(doc.ref, data: {"status": Shiftplan.STATUS_PUBLIC});
    }

    return batch.commit();
  }
}
