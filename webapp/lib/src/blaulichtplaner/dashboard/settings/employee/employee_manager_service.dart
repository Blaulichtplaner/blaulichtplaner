import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart' as models;
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';

@Injectable()
class EmployeeManagerService {
  final firestore = fb.firestore();

  Future<List<TransportResult<models.Employee>>> getEmployees(String companyId) async {
    DocumentReference companyRef = firestore.collection("companies").doc(companyId);
    final result = <TransportResult<models.Employee>>[];
    final snapshot = await firestore
        .collection("employees")
        .where("companyRefs", "array-contains", companyRef)
        .orderBy("lastName")
        .orderBy("firstName")
        .get();
    await Future.forEach(snapshot.docs, (documentSnapshot) async {
      result.add(new TransportResult(documentSnapshot.ref, models.Employee.fromSnapshot(documentSnapshot)));
    });
    return result;
  }
}
