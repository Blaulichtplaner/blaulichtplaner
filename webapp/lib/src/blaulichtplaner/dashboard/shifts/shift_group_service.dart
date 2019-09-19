abstract class ShiftVoteInterface {
  DateTime get from;

  DateTime get to;

  String get locationLabel;

  String get workAreaLabel;

  int get group;

  set group(int value);
  
  bool get selected;
  set selected(bool value);
  
  bool get highlighted;
  set highlighted(bool value);
}

class ShiftDayContainer {
  DateTime day;
  List<ShiftVoteInterface> shiftVotes = [];

  ShiftDayContainer(this.day, this.shiftVotes);
}

class _GroupHolder {
  int id;
  List<ShiftVoteInterface> shifts = [];

  _GroupHolder(this.id, ShiftVoteInterface shift) {
    shift.group = id;
    shifts.add(shift);
  }

  void add(ShiftVoteInterface shift) {
    shift.group = id;
    if (_isFirstAdjacent(shift)) {
      shifts.insert(0, shift);
    } else {
      shifts.add(shift);
    }
  }

  // FIXME der vergleich der location sollte über die ref laufen
  bool _isSameLocationAndWorkArea(ShiftVoteInterface first, ShiftVoteInterface second) {
    return first.locationLabel == second.locationLabel && first.workAreaLabel == second.workAreaLabel;
  }

  bool isAdjacent(ShiftVoteInterface shift) {
    return _isSameLocationAndWorkArea(shifts.first, shift) && (_isFirstAdjacent(shift) || _isLastAdjacent(shift));
  }

  bool _isLastAdjacent(ShiftVoteInterface shift) => shifts.last.to.isAtSameMomentAs(shift.from);

  bool _isFirstAdjacent(ShiftVoteInterface shift) => shifts.first.from.isAtSameMomentAs(shift.to);
}

int _byFromAndLocationAndWorkArea(ShiftVoteInterface sv1, ShiftVoteInterface sv2) {
  int c = sv1.from.compareTo(sv2.from);
  if (c == 0) {
    c = sv1.locationLabel.compareTo(sv2.locationLabel);
    if (c == 0) {
      return sv1.workAreaLabel.compareTo(sv2.workAreaLabel);
    }
  }
  return c;
}

int _byLocationAndWorkAreaAndFrom(ShiftVoteInterface sv1, ShiftVoteInterface sv2) {
  int c = sv1.locationLabel.compareTo(sv2.locationLabel);
  if (c == 0) {
    c = sv1.workAreaLabel.compareTo(sv2.workAreaLabel);
    if (c == 0) {
      return sv1.from.compareTo(sv2.from);
    }
  }
  return c;
}

class ShiftGroupService {
  void injectShiftGroups(List<ShiftVoteInterface> shifts) {
    List<ShiftVoteInterface> shiftsToGroup = List.from(shifts);
    shiftsToGroup.sort(_byFromAndLocationAndWorkArea);

    List<_GroupHolder> groupHolderList = [];
    int groupId = 1;
    while (shiftsToGroup.isNotEmpty) {
      ShiftVoteInterface shiftToTest = shiftsToGroup.removeLast();
      bool wasAdjacent = false;
      for (_GroupHolder groupHolder in groupHolderList) {
        if (groupHolder.isAdjacent(shiftToTest)) {
          wasAdjacent = true;
          groupHolder.add(shiftToTest);
          break;
        }
      }
      if (!wasAdjacent) {
        groupHolderList.add(_GroupHolder(groupId++, shiftToTest));
      }
    }
  }

  List<ShiftDayContainer> groupShiftVotes(List<ShiftVoteInterface> filteredShifts) {
    Map<DateTime, List<ShiftVoteInterface>> groupedShiftVotes = {};

    for (ShiftVoteInterface shiftVote in filteredShifts) {
      DateTime shiftVoteFrom = shiftVote.from;
      DateTime day = DateTime(shiftVoteFrom.year, shiftVoteFrom.month, shiftVoteFrom.day);
      List<ShiftVoteInterface> shifts = groupedShiftVotes.putIfAbsent(day, () => <ShiftVoteInterface>[]);
      shifts.add(shiftVote);
    }

    List<ShiftDayContainer> result = [];
    for (MapEntry<DateTime, List<ShiftVoteInterface>> entry in groupedShiftVotes.entries) {
      List<ShiftVoteInterface> shiftList = entry.value;
      shiftList.sort(_byLocationAndWorkAreaAndFrom);
      result.add(ShiftDayContainer(entry.key, shiftList));
    }

    result.sort((sdc1, sdc2) => sdc1.day.compareTo(sdc2.day));

    return result;
  }
}
