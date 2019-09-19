import 'package:angular/angular.dart';
import 'package:angular_components/model/date/date.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/employee_select_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shift_assignment_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/date_utils.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';

@Injectable()
class ShiftService {
  final FirebaseService _firebaseService;
  final ShiftAssignmentService _shiftAssignmentService;

  ShiftService(this._firebaseService) : _shiftAssignmentService = new ShiftAssignmentService(_firebaseService);

  _storeShift(bool newShift, ShiftModel shift) async {
    final firestore = _firebaseService.firestore;
    Map<String, Object> shiftData = {};
    if (newShift) {
      shiftData["created"] = DateTime.now();
      shiftData["shiftplanRef"] = shift.shiftplanRef;
    }
    final workArea = shift.selectedWorkArea.selectedValues.first;
    Iterable<EmployeePath> assignedEmployees = shift.assignedEmployees.selectedValues;
    shiftData["from"] = shift.from;
    shiftData["to"] = shift.to;
    shiftData["workAreaRef"] = firestore.doc(workArea.path);
    shiftData["workAreaLabel"] = workArea.uiDisplayName;
    shiftData["requiredEmployees"] = shift.requiredEmployees;
    shiftData["privateNote"] = shift.privateNote;
    shiftData["publicNote"] = shift.publicNote;
    shiftData["acceptBid"] = shift.acceptBid;
    shiftData["locationLabel"] = shift.locationLabel;
    shiftData["locationRef"] = shift.locationRef;
    shiftData["companyRef"] = shift.companyRef;
    shiftData["status"] = shift.status;
    shiftData["manned"] = assignedEmployees.length >= shift.requiredEmployees;

    if (newShift) {
      shift.shiftRef = await firestore.collection("shifts").add(shiftData);
    } else {
      shift.shiftRef.update(data: shiftData);
    }
    await _shiftAssignmentService.updateAssignments(shift, shift.shiftplanRef, assignedEmployees);
  }

  saveShift(ShiftModel shift) async {
    bool newShift = shift.isNew;
    await _storeShift(newShift, shift);
    if (shift.repeatDates.isNotEmpty) {
      final workingHours = WorkingHours.fromTo(shift.from, shift.to);
      for (final shiftDate in shift.repeatDates) {
        shift.from = DateTimeUtils.dateTimeWithTimeFrom(shiftDate, workingHours.from);
        shift.to = DateTimeUtils.dateTimeWithEndTime(shiftDate, workingHours);
        await _storeShift(newShift, shift);
      }
    }
  }

  assignEmployeesToShifts(List<EmployeePath> assignedEmployees, Iterable<Shift> selectedShifts) async {
    for (Shift shift in selectedShifts) {
      Map<String, Object> shiftData = {};
      shiftData["manned"] = assignedEmployees.length >= shift.requiredEmployees;
      await shift.shiftRef.update(data: shiftData);
      await _shiftAssignmentService.updateAssignments(ShiftModel.fromShift(shift), shift.shiftplanRef, assignedEmployees);
    }
  }

  deleteShift(DocumentReference shiftRef) async {
    var futures = await _shiftAssignmentService.deleteAssignments(shiftRef);
    futures.add(shiftRef.delete());
    return futures;
  }
}
