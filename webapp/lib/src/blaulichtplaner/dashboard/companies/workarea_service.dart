import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';

@Injectable()
class WorkAreaService {
  final firestore = fb.firestore();

  Future<List<TransportResult<LocationWorkArea>>> getWorkAreaForCompanyAndLocation(
      DocumentReference locationRef) async {
    final result = <TransportResult<LocationWorkArea>>[];
    final snapshot = await locationRef.collection("workAreas").get();
    await Future.forEach(snapshot.docs, (documentSnapshot) async {
      result.add(new TransportResult(documentSnapshot.ref, new LocationWorkArea.fromMap(documentSnapshot.data())));
    });
    return result;
  }

  getWorkArea(DocumentReference locationRef, String workAreaId) async {
    final snapshot = await locationRef.collection("workAreas").doc(workAreaId).get();
    return new TransportResult(snapshot.ref, new LocationWorkArea.fromMap(snapshot.data()));
  }
}

@Injectable()
class WorkAreaResolver {
  final Map<String, LocationWorkArea> workAreaMap = {};

  init(List<TransportResult<LocationWorkArea>> workAreas) {
    print("${this.hashCode} init workareas");

    for (final tr in workAreas) {
      workAreaMap[tr.selfPath] = tr.data;
    }
  }

  String resolveToColor(DocumentReference ref) {
    return workAreaMap[ref.path]?.color;
  }
}
