import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:firebase/firestore.dart';

@Injectable()
class WorkingHoursService {
  save(DocumentReference locationRef, WorkingHours workingHours) {
    return locationRef.collection("workingHours").add(workingHours.toMap());
  }

  delete(DocumentReference workingHoursRef) {
    return workingHoursRef.delete();
  }

  Future<List<TransportResult<WorkingHours>>> getWorkingHoursForCompany(DocumentReference locationRef) async {
    final result = <TransportResult<WorkingHours>>[];
    final snapshot = await locationRef.collection("workingHours").get();
    await Future.forEach(snapshot.docs, (documentSnapshot) async {
      result.add(new TransportResult(
          documentSnapshot.ref, new WorkingHours.fromMap(documentSnapshot.data())));
    });
    return result;
  }
}
