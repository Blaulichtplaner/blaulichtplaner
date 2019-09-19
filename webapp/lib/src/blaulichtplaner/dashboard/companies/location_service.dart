import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';

@Injectable()
class LocationService {
  final firestore = fb.firestore();

  Future<List<TransportResult<CompanyLocation>>> getLocationsForCompany(String companyId) async {
    final result = <TransportResult<CompanyLocation>>[];
    final snapshot = await firestore.doc("/companies/${companyId}").collection("locations").get();
    await Future.forEach(snapshot.docs, (DocumentSnapshot documentSnapshot) async {
      result.add(new TransportResult(
          documentSnapshot.ref, CompanyLocation.fromMap(documentSnapshot.data())));
    });
    return result;
  }

  getLocation(DocumentReference companyRef, String locationId) async {
    final snapshot = await companyRef.collection("locations").doc(locationId).get();
    return new TransportResult(snapshot.ref, CompanyLocation.fromMap(snapshot.data()));
  }
}
