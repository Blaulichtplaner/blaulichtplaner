import 'dart:async';

import 'package:angular_components/angular_components.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workarea_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/employee_select_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/models.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';
import 'package:firebase/firestore.dart';

class Bid {
  DocumentReference selfRef;
  DateTime from;
  DateTime to;
  DocumentReference shiftplanRef;
  DocumentReference shiftRef;
  DocumentReference employeeRef;
  String employeeLabel;

  Bid.fromSnapshot(DocumentSnapshot snapshot) {
    this.selfRef = snapshot.ref;
    this.from = snapshot.get("from");
    this.to = snapshot.get("to");
    this.shiftplanRef = snapshot.get("shiftplanRef");
    this.shiftRef = snapshot.get("shiftRef");
    this.employeeRef = snapshot.get("employeeRef");
    this.employeeLabel = snapshot.get("employeeLabel");
  }
}

class AssignmentTask {
  String type = "assignment";
  String reference;
  String remarks;
  DateTime taskTime = DateTime.now();

  AssignmentTask(this.reference);

  AssignmentTask.fromData(Map<String, dynamic> data) {
    this.type = data["type"];
    this.reference = data["reference"];
    this.remarks = data["remarks"];
    this.taskTime = data["taskTime"];
  }
}

class Evaluation {
  DocumentReference selfRef;
  DateTime actualFrom;
  DateTime actualTo;
  DocumentReference assignmentRef;
  DocumentReference shiftRef;
  DocumentReference shiftplanRef;
  DocumentReference employeeRef;
  DateTime updated;
  int reasonOvertime;
  String remarks;
  String managerRemarks;
  List<AssignmentTask> tasks = [];
  bool didNotAppear;
  bool finished;
  String status;

  void updateWithSnapshot(DocumentSnapshot snapshot) {
    selfRef = snapshot.ref;
    actualFrom = snapshot.get("actualFrom");
    actualTo = snapshot.get("actualTo");
    assignmentRef = snapshot.get("assignmentRef");
    shiftRef = snapshot.get("shiftRef");
    shiftplanRef = snapshot.get("shiftplanRef");
    employeeRef = snapshot.get("employeeRef");
    updated = snapshot.get("updated");
    reasonOvertime = snapshot.get("reasonOvertime");
    remarks = snapshot.get("remarks");
    managerRemarks = snapshot.get("managerRemarks");
    tasks = (snapshot.get("tasks") as List<dynamic>).map((data) => AssignmentTask.fromData(data)).toList();
    didNotAppear = snapshot.get("didNotAppear");
    finished = snapshot.get("finished");
    status = snapshot.get("status");
  }
}

class AssignmentEvaluation extends FirestoreSelectOption {
  Evaluation evaluation = Evaluation();
  bool loading = true;
  bool expanded = false;

  bool get finished => evaluation.finished != null && evaluation.finished;

  AssignmentEvaluation(DocumentReference ref, String label, DocumentReference assignmentRef) : super(ref, label) {
    assert(assignmentRef != null);
    evaluation.assignmentRef = assignmentRef;
    evaluation.employeeRef = ref;
  }
}

class Assignment extends FirestoreSelectOption {
  DocumentReference assignmentRef;
  String status;

  Assignment(DocumentReference employeeRef, String employeeLabel, this.assignmentRef)
      : super(employeeRef, employeeLabel);
}

class ShiftModel {
  final DocumentReference shiftplanRef;
  final DocumentReference companyRef;
  DocumentReference shiftRef;
  DateTime from;
  DateTime to;
  int requiredEmployees = 1;
  String privateNote;
  String publicNote;
  String locationLabel;
  DocumentReference locationRef;
  bool acceptBid = true;
  String status;

  Set<Date> repeatDates = new Set();
  SelectionModel<FirestoreSelectOption> selectedWorkArea = new SelectionModel.single();
  SelectionModel<EmployeePath> assignedEmployees = new SelectionModel.multi();

  List<Bid> bids = [];
  
  ShiftModel.fromShift(Shift shift) : this.shiftplanRef = shift.shiftplanRef, this.companyRef = shift.companyRef {
    this.shiftRef = shift.shiftRef;
    this.from = DateTime.fromMillisecondsSinceEpoch(shift.from.millisecondsSinceEpoch);
    this.to = DateTime.fromMillisecondsSinceEpoch(shift.to.millisecondsSinceEpoch);
    this.requiredEmployees = shift.requiredEmployees;
    this.privateNote = shift.privateNote;
    this.publicNote = shift.publicNote;
    this.locationLabel = shift.locationLabel;
    this.locationRef = shift.locationRef;
    this.acceptBid = shift.acceptBid;
    if (shift.workAreaRef != null) {
      this.selectedWorkArea =
          SelectionModel.single(selected: FirestoreSelectOption(shift.workAreaRef, shift.workAreaLabel));
    } else {
      this.selectedWorkArea = SelectionModel.single();
    }
    this.assignedEmployees = SelectionModel.multi(
        selectedValues: shift.getAssignedEmployees().map((assignment) => SelectablePath(assignment.ref.path, assignment.uiDisplayName)).toList());
    this.bids = List.from(shift.bids);
  }

  bool hasBids() => bids.isNotEmpty;

  int bidCount() => bids.length;

  bool get isNew => shiftRef == null;

  String get workArea => selectedWorkArea.isEmpty
      ? "Arbeitsbereich nicht ausgewählt"
      : selectedWorkArea.selectedValues.first.uiDisplayName;

  getAssignedEmployees() {
    return assignedEmployees == null ? 0 : assignedEmployees.selectedValues.length;
  }
}

class Shift {
  final DocumentReference shiftplanRef;
  final DocumentReference companyRef;
  DocumentReference shiftRef;
  DateTime from;
  DateTime to;
  DateTime overtimeFrom;
  DateTime overtimeTo;
  int requiredEmployees = 1;
  String privateNote;
  String publicNote;
  String locationLabel;
  DocumentReference locationRef;
  bool acceptBid = true;
  String status;
  DocumentReference workAreaRef;
  String workAreaLabel;
  String workAreaColor;
  bool incomplete = false;

  SelectionModel<Assignment> _assignedEmployees = new SelectionModel.multi();
  Map<String, Evaluation> evaluations = {};

  List<Bid> bids = [];

  Shift.empty(this.shiftplanRef, this.companyRef);

  Shift.fromSnapshot(DocumentSnapshot snapshot) : shiftplanRef = snapshot.get("shiftplanRef"), companyRef = snapshot.get("companyRef") {
    shiftRef = snapshot.ref;
    from = snapshot.get("from");
    to = snapshot.get("to");
    requiredEmployees = snapshot.get("requiredEmployees");
    privateNote = snapshot.get("privateNote");
    publicNote = snapshot.get("publicNote");
    locationLabel = snapshot.get("locationLabel");
    locationRef = snapshot.get("locationRef");
    acceptBid = snapshot.get("acceptBid") == null ? false : snapshot.get("acceptBid");
    status = snapshot.get("status");
    workAreaRef = snapshot.get("workAreaRef");
    workAreaLabel = snapshot.get("workAreaLabel");
    incomplete = _assignedEmployees.selectedValues.length < requiredEmployees;
  }

  DateTime get displayFrom => overtimeFrom != null ? overtimeFrom : from;

  DateTime get displayTo => overtimeTo != null ? overtimeTo : to;

  addBid(Bid bid) {
    bids.add(bid);
  }

  deleteBid(Bid bid) {
    bids.removeWhere((knownBid) => knownBid.shiftRef.path == bid.shiftRef.path);
  }

  bool hasBids() => bids.isNotEmpty;

  int bidCount() => bids.length;

  updateWith(Shift shift) {
    from = shift.from;
    to = shift.to;
    requiredEmployees = shift.requiredEmployees;
    privateNote = shift.privateNote;
    publicNote = shift.publicNote;
    acceptBid = shift.acceptBid;
    locationLabel = shift.locationLabel;
    locationRef = shift.locationRef;
    status = shift.status;
    workAreaRef = shift.workAreaRef;
    workAreaLabel = shift.workAreaLabel;
    workAreaColor = shift.workAreaColor;
    incomplete = _assignedEmployees.selectedValues.length < requiredEmployees;
  }

  bool get isNew => shiftRef == null;

  Iterable<Assignment> getAssignedEmployees() {
    return _assignedEmployees.selectedValues;
  }

  select(Assignment assignment) {
    _assignedEmployees.select(assignment);
    incomplete = _assignedEmployees.selectedValues.length < requiredEmployees;
  }

  deselect(Assignment assignment) {
    _assignedEmployees.deselect(assignment);
    incomplete = _assignedEmployees.selectedValues.length < requiredEmployees;
  }

  updateAssignments() {
    overtimeFrom = null;
    overtimeTo = null;
    for (final employee in _assignedEmployees.selectedValues) {
      employee.status = _evaluationStatus(employee);
    }
  }

  String _evaluationStatus(Assignment assignment) {
    final evaluation = evaluations[assignment.assignmentRef.path];
    if (evaluation != null) {
      if (evaluation.finished) {
        if (!evaluation.actualTo.isAtSameMomentAs(to)) {
          overtimeTo = evaluation.actualTo;
        }
        if (!evaluation.actualFrom.isAtSameMomentAs(from)) {
          overtimeFrom = evaluation.actualFrom;
        }
        if (evaluation.status == "confirmed") {
          return "done_all";
        } else {
          return "done";
        }
      }
    }
    return "none";
  }

  bool hasAssignments() {
    return _assignedEmployees.isNotEmpty;
  }
}

int shiftCompare(Shift s1, Shift s2) {
  int c = s1.from.compareTo(s2.from);
  if (c == 0) {
    return s1.workAreaLabel.compareTo(s2.workAreaLabel);
  } else {
    return c;
  }
}

class ShiftDay {
  Date day;
  bool today;

  int get dayNo => day.day;
  bool partOfShiftplan;
  List<Shift> shifts = [];

  ShiftDay(this.day, this.today);

  void addShift(Shift shift) {
    shifts.add(shift);
    shifts.sort(shiftCompare);
  }
}

class ShiftWeek {
  int weekNo;
  bool currentWeek;
  List<ShiftDay> shiftDays = [];

  ShiftWeek(this.weekNo, this.currentWeek);
}

class ShiftplanStats {
  int days;
  int shifts;
  int employeeShifts;
  int employees;
  int assignmentTasks;
  int finishedEvaluations;
  int rejectedEvaluations;
  int confirmedEvaluations;
  int workedMinutes;
  int plannedMinutes;
  int overtimeMinutes;

  reset() {
    days = 0;
    shifts = 0;
    employeeShifts = 0;
    employees = 0;
    assignmentTasks = 0;
    finishedEvaluations = 0;
    rejectedEvaluations = 0;
    confirmedEvaluations = 0;
    workedMinutes = 0;
    plannedMinutes = 0;
    overtimeMinutes = 0;
  }
}

class ShiftplanData {
  final WorkAreaResolver _workAreaResolver;
  final Firestore _firestore;

  final ShiftplanStats stats = ShiftplanStats();

  DocumentReference selfRef;
  String label;
  bool planning;
  List<String> headers = ["KW", "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
  List<ShiftWeek> shiftWeeks = [];
  StreamSubscription<QuerySnapshot> _shiftsSubscription;
  StreamSubscription<QuerySnapshot> _assignmentsSubscription;
  StreamSubscription<QuerySnapshot> _bidsSubscription;
  StreamSubscription<QuerySnapshot> _evaluationsSubscription;

  SelectionModel<Shift> selectedShifts = new SelectionModel.multi();

  ShiftplanData.withShiftplan(this._workAreaResolver, this._firestore, Shiftplan shiftplan) {
    selfRef = shiftplan.selfRef;
    label = shiftplan.label;
    planning = shiftplan.isPlanning();

    Date today = Date.today();

    Date startTime = Date.fromTime(shiftplan.from);
    Date endTime = Date.fromTime(shiftplan.to);
    Date countingDay = Date.fromTime(_weekStart(startTime.asUtcTime()));

    while (countingDay.isBefore(endTime)) {
      ShiftWeek shiftWeek = ShiftWeek(weekNumber(countingDay), false);
      for (int x = 0; x < 7; x++) {
        Date day = Date(countingDay.year, countingDay.month, countingDay.day);
        if (day == today) {
          shiftWeek.currentWeek = true;
        }
        ShiftDay shiftDay = ShiftDay(day, day == today);
        shiftDay.partOfShiftplan = !day.isBefore(startTime) && day.isBefore(endTime);
        shiftWeek.shiftDays.add(shiftDay);
        countingDay = countingDay.add(days: 1);
      }
      shiftWeeks.add(shiftWeek);
    }
  }

  _updateStats() {
    Set<String> countedEmployees = Set();
    stats.reset();
    for (ShiftWeek week in shiftWeeks) {
      for (ShiftDay day in week.shiftDays) {
        if (day.partOfShiftplan) {
          stats.days++;
          for (Shift shift in day.shifts) {
            stats.shifts++;
            for (Assignment assignment in shift.getAssignedEmployees()) {
              final plannedMinutes = shift.to.difference(shift.from).inMinutes;
              stats.plannedMinutes += plannedMinutes;
              if (!countedEmployees.contains(assignment.ref.path)) {
                stats.employees++;
                countedEmployees.add(assignment.ref.path);
              }
              stats.employeeShifts++;
              if (assignment.status == "done_all") {
                stats.confirmedEvaluations++;
              } else if (assignment.status == "done") {
                stats.finishedEvaluations++;
              }
              Evaluation evaluation = shift.evaluations[assignment.assignmentRef.path];
              if (evaluation != null) {
                stats.assignmentTasks += evaluation.tasks.length;
                if (evaluation.actualFrom != null && evaluation.actualTo != null) {
                  final workedMinutes = evaluation.actualTo.difference(evaluation.actualFrom).inMinutes;
                  stats.workedMinutes += workedMinutes;
                  if (workedMinutes > plannedMinutes) {
                    stats.overtimeMinutes += workedMinutes - plannedMinutes;
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  static DateTime _weekStart(DateTime date) {
    return date.add(new Duration(days: -((date.weekday - DateTime.monday) % 7)));
  }

  listenForShifts() {
    _shiftsSubscription =
        _firestore.collection("shifts").where("shiftplanRef", "==", selfRef).onSnapshot.listen((snapshot) {
      snapshot.docChanges().forEach((docChange) {
        final snapshot = docChange.doc;
        Shift shift = Shift.fromSnapshot(snapshot);
        shift.workAreaColor = _workAreaResolver.resolveToColor(shift.workAreaRef);

        if (docChange.type == "added") {
          final shiftDay = findByTime(shift.from);
          if (shiftDay != null) {
            shiftDay.addShift(shift);
          }
        } else if (docChange.type == "removed") {
          removeByPath(shift.shiftRef.path);
        } else if (docChange.type == "modified") {
          Shift oldShift = findByPath(shift.shiftRef.path);
          oldShift.updateWith(shift);
        }
      });
      _updateStats();
    });
  }

  listenForAssignments() {
    _assignmentsSubscription =
        _firestore.collection("assignments").where("shiftplanRef", "==", selfRef).onSnapshot.listen((snapshot) {
      snapshot.docChanges().forEach((docChange) {
        final snapshot = docChange.doc;
        DocumentReference assignmentRef = snapshot.ref;
        DocumentReference shiftRef = snapshot.get("shiftRef");
        DocumentReference employeeRef = snapshot.get("employeeRef");
        String employeeLabel = snapshot.get("employeeLabel");
        final shift = findByPath(shiftRef.path);
        if (shift != null) {
          if (docChange.type == "added" || docChange.type == "modified") {
            shift.select(new Assignment(employeeRef, employeeLabel, assignmentRef));
          } else if (docChange.type == "removed") {
            shift.deselect(new Assignment(employeeRef, employeeLabel, assignmentRef));
          }
          shift.updateAssignments();
        } else {
          print("ERROR: No shift for assignment");
          // FIXME: delete assignment
        }
      });
      _updateStats();
    });
  }

  listenForEvaluations() {
    _evaluationsSubscription =
        _firestore.collection("evaluations").where("shiftplanRef", "==", selfRef).onSnapshot.listen((snapshot) {
      snapshot.docChanges().forEach((docChange) {
        final snapshot = docChange.doc;
        DocumentReference assignmentRef = snapshot.get("assignmentRef");
        DocumentReference shiftRef = snapshot.get("shiftRef");
        Evaluation evaluation = Evaluation();
        evaluation.updateWithSnapshot(snapshot);
        final shift = findByPath(shiftRef.path);
        print("Evaluation ${docChange.type} - ${assignmentRef.path}");
        if (shift != null) {
          if (docChange.type == "added" || docChange.type == "modified") {
            shift.evaluations[assignmentRef.path] = evaluation;
          } else if (docChange.type == "removed") {
            shift.evaluations.remove(assignmentRef.path);
          }
          shift.updateAssignments();
        } else {
          print("ERROR: No shift for evaluation");
          // FIXME: delete evaluation
        }
      });
      _updateStats();
    });
  }

  listenForBids() {
    _bidsSubscription = _firestore
        .collection("shiftVotes")
        .where("shiftplanRef", "==", selfRef)
        .where("isBid", "==", true)
        .onSnapshot
        .listen((snapshot) {
      snapshot.docChanges().forEach((docChange) {
        final snapshot = docChange.doc;
        print("getting bid docs");
        Bid bid = Bid.fromSnapshot(snapshot);
        final shift = bid.shiftRef != null ? findByPath(bid.shiftRef.path) : null;
        if (shift != null) {
          if (docChange.type == "added") {
            shift.addBid(bid);
          } else if (docChange.type == "modified") {
            shift.deleteBid(bid);
            shift.addBid(bid);
          } else if (docChange.type == "removed") {
            shift.deleteBid(bid);
          }
        } else {
          print("bid has no known shift");
          // TODO show bid as part of day
        }
      });
    });
  }

  void clear() {
    selectedShifts.clear();

    _shiftsSubscription?.cancel();
    _assignmentsSubscription?.cancel();
    _bidsSubscription?.cancel();
    _evaluationsSubscription?.cancel();
  }

  DateTime firstDateTime() {
    // FIXME skip days outside shiftplan
    if (shiftWeeks.isNotEmpty) {
      if (shiftWeeks.first.shiftDays.isNotEmpty) {
        final day = shiftWeeks.first.shiftDays.first.day;
        return new DateTime(day.year, day.month, day.day);
      }
    }
    return null;
  }

  DateTime lastDateTime() {
    // FIXME skip days outside shiftplan
    if (shiftWeeks.isNotEmpty) {
      if (shiftWeeks.last.shiftDays.isNotEmpty) {
        final day = shiftWeeks.last.shiftDays.last.day;
        return new DateTime(day.year, day.month, day.day);
      }
    }
    return null;
  }

  ShiftDay findByTime(DateTime startTime) {
    Date startDate = new Date.fromTime(startTime);
    ShiftDay result = null;
    shiftWeeks.forEach((shiftWeek) {
      final weekResult = shiftWeek.shiftDays.firstWhere((shiftDay) {
        Date day = shiftDay.day;
        return (startDate == day);
      }, orElse: () => null);
      if (weekResult != null) {
        result = weekResult;
      }
    });
    return result;
  }

  Shift findByPath(String shiftPath) {
    Shift result = null;
    shiftWeeks.forEach((shiftWeek) {
      shiftWeek.shiftDays.forEach((shiftDay) {
        shiftDay.shifts.forEach((shift) {
          if (shiftPath == shift.shiftRef.path) {
            result = shift;
          }
        });
      });
    });
    return result;
  }

  removeByPath(String shiftPath) {
    shiftWeeks.forEach((shiftWeek) {
      shiftWeek.shiftDays.forEach((shiftDay) {
        shiftDay.shifts.removeWhere((shift) => shiftPath == shift.shiftRef.path);
      });
    });
  }
}
