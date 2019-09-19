import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/availability_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';

@Injectable()
class AssignmentService {
  final FirebaseService _firebaseService;

  AssignmentService(this._firebaseService);

  Future<List<SimpleDateRange>> getEmployeeAvailability(DocumentReference employeeRef, SimpleDateRange dateRange) async {
    DateTime rangeFrom = dateRange.from.subtract(Duration(days: 1));
    DateTime rangeTo = dateRange.to.add(Duration(days: 1));

    QuerySnapshot query = await _firebaseService.firestore
        .collection("assignments")
        .where("employeeRef", "==", employeeRef)
        .where("from", ">=", rangeFrom)
        .where("from", "<=", rangeTo)
        .get();
    List<SimpleDateRange> shiftRanges = [];
    if (!query.empty) {
      query.forEach((snapshot) {
        DateTime from = snapshot.get("from");
        DateTime to = snapshot.get("to");
        DocumentReference locationRef = snapshot.get("locationRef");
        shiftRanges.add(SimpleDateRange(from, to, locationRef.path));
      });
    }
    return shiftRanges;
  }
}
