import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/filter_options_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/shift_group_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/shift_models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/shift_vote_holder.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/utils/company_aware.dart';
import 'package:blaulichtplaner/src/utils/loadable.dart';
import 'package:firebase/firestore.dart';

@Component(
    selector: "blp-shift-list",
    templateUrl: "shift_list_component.html",
    styles: [".highlight-shift {background-color: #EBEDF7 !important;}"],
    directives: [materialDirectives, coreDirectives, routerDirectives, FilterOptionsComponent],
    pipes: [DatePipe])
class ShiftListComponent extends Object with Loadable, CompanyAware implements OnActivate, OnInit, OnDestroy {
  final FirebaseService _firebaseService;
  final UserService _userService;
  final ContextService _contextService;
  final List<StreamSubscription> _subs = [];
  final ShiftVoteHolder _shiftVoteHolder = ShiftVoteHolder();

  List<ShiftDayContainer> groupedShifts = [];

  ShiftListComponent(this._firebaseService, this._contextService, this._userService);

  String shiftsTitle = "Unbesetzte Dienste";
  FilterConfig filterConfig = FilterConfig();

  void rejectShift(ShiftVote shiftVote) async {
    await _save(shiftVote.shift, false);
  }

  void bidShift(ShiftVote shiftVote) async {
    await _save(shiftVote.shift, true);
  }

  void selectGroup(ShiftVoteInterface shift) {
    for (ShiftDayContainer sdc in groupedShifts) {
      for (ShiftVoteInterface svi in sdc.shiftVotes) {
        svi.highlighted = svi.group == shift.group;
      }
    }
  }

  void deselectGroup() {
    for (ShiftDayContainer sdc in groupedShifts) {
      for (ShiftVoteInterface svi in sdc.shiftVotes) {
        svi.highlighted = false;
      }
    }
  }

  Future<DocumentReference> _save(Shift shift, bool isBid) async {
    DocumentSnapshot employeeSnapshot = await shift.role.reference.get();
    Employee employee = Employee.fromSnapshot(employeeSnapshot);
    Vote vote = Vote.fromShift(shift, isBid, shift.role.reference, employee.uiDisplayName);
    final data = <String, dynamic>{};
    data["isBid"] = vote.isBid;
    data["from"] = vote.from;
    data["to"] = vote.to;
    data["shiftplanRef"] = vote.shiftplanRef;
    data["shiftRef"] = vote.shiftRef;
    data["employeeRef"] = vote.employeeRef;
    data["employeeLabel"] = vote.employeeLabel;
    if (vote.selfRef != null) {
      data["updated"] = DateTime.now();
      await vote.selfRef.set(data);
      return vote.selfRef;
    } else {
      data["created"] = DateTime.now();
      final collection = _firebaseService.firestore.collection("shiftVotes");
      final ref = await collection.add(data);
      return ref;
    }
  }

  Future<void> delete(Vote vote) {
    return vote.selfRef.delete();
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    if (_contextService.selectedCompanyLocation != null) {
      initWithCompanyAndLocation();
    }
  }

  @override
  Future initWithCompanyAndLocation() async {
    startLoading();
    _cancelSubscriptions();
    await _initWorkAreaShifts();
    await _initOwnVotes();
    finishLoading();
  }

  void _initWorkAreaShifts() async {
    BlpUser user = await _userService.getUser();
    for (Role role in user.rolesForType("employee")) {
      print("query for companyRef: ${role.companyRef.path}");

      final queryStream = _firebaseService.firestore
          .collection("shifts")
          .where("from", ">=", DateTime.now())
          .where("acceptBid", "==", true)
          .where("manned", "==", false)
          .where("status", "==", "public")
          .where("companyRef", "==", role.companyRef)
          .onSnapshot;
      _subs.add(queryStream.listen((snapshot) {
        for (final change in snapshot.docChanges()) {
          print("shift ${change.type}");

          if (change.type == "added") {
            _shiftVoteHolder.addShift(Shift.fromSnapshot(change.doc, role));
          } else if (change.type == "modified") {
            _shiftVoteHolder.modifyShift(Shift.fromSnapshot(change.doc, role));
          } else if (change.type == "removed") {
            _shiftVoteHolder.removeShift(Shift.fromSnapshot(change.doc, role));
          }
        }
        filterShiftVotes();
      }));
    }
  }

  void _initOwnVotes() async {
    BlpUser user = await _userService.getUser();
    for (Role role in user.rolesForType("employee")) {
      final queryStream = _firebaseService.firestore
          .collection("shiftVotes")
          .where("employeeRef", "==", role.reference)
          .where("from", ">=", DateTime.now())
          .onSnapshot;
      _subs.add(queryStream.listen((snapshot) {
        for (final change in snapshot.docChanges()) {
          print("vote: ${change.type}");
          if (change.type == "added") {
            _shiftVoteHolder.addVoteFromSnapshot(change.doc);
          } else if (change.type == "modified") {
            _shiftVoteHolder.modifyVoteFromSnapshot(change.doc);
          } else if (change.type == "removed") {
            _shiftVoteHolder.removeVoteFromSnapshot(change.doc);
          }
        }
        filterShiftVotes();
      }));
    }
  }

  Function _filterByFilterConfig(FilterConfig filterConfig) {
    return (ShiftVote shiftVote) {
      if (filterConfig.option == FilterOption.withoutVote) {
        if (shiftVote.hasVote()) {
          return false;
        }
      } else if (filterConfig.option == FilterOption.accepted) {
        if (!shiftVote.hasVote() || !shiftVote.vote.isBid) {
          return false;
        }
      } else if (filterConfig.option == FilterOption.rejected) {
        if (!shiftVote.hasVote() || shiftVote.vote.isBid) {
          return false;
        }
      }
      DateTime selectedDate = filterConfig.selectedDate;
      if (selectedDate != null) {
        return (shiftVote.shift.from.day == selectedDate.day) &&
            (shiftVote.shift.from.month == selectedDate.month) &&
            (shiftVote.shift.from.year == selectedDate.year);
      } else {
        return true;
      }
    };
  }

  void filterShiftVotes() {
    List<ShiftVote> filteredShifts = _shiftVoteHolder.shiftVotes.where(_filterByFilterConfig(filterConfig)).toList();
    ShiftGroupService shiftGroupService = ShiftGroupService();
    shiftGroupService.injectShiftGroups(filteredShifts);
    groupedShifts = shiftGroupService.groupShiftVotes(filteredShifts);
  }

  @override
  void ngOnDestroy() {
    cancelListener();
    _cancelSubscriptions();
  }

  void _cancelSubscriptions() {
    for (StreamSubscription sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  @override
  void ngOnInit() {
    startLoading();
    initCompanyListener(_contextService);
  }
}
