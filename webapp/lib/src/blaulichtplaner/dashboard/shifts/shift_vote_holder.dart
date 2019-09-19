import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/shift_group_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/shift_models.dart';
import 'package:firebase/firestore.dart';

class ShiftVote extends ShiftVoteInterface {
  Shift shift;
  Vote vote;
  int _group;
  bool _selected = false;
  bool _highlighted = false;

  ShiftVote({this.shift, this.vote});

  int get group => _group;

  set group(int value) {
    _group = value;
  }

  bool get selected => _selected;

  set selected(bool value) {
    _selected = value;
  }

  bool get highlighted => _highlighted;

  set highlighted(bool value) {
    _highlighted = value;
  }

  String get durationLabel {
    if (shift != null) {
      return shift.durationLabel;
    } else {
      return null;
    }
  }

  String get publicNote {
    if (shift != null) {
      return shift.publicNote;
    } else {
      return null;
    }
  }

  DateTime get from {
    if (shift != null) {
      return shift.from;
    } else {
      return vote.from;
    }
  }

  DateTime get to {
    if (shift != null) {
      return shift.to;
    } else {
      return vote.to;
    }
  }

  String get workAreaLabel {
    if (shift != null) {
      return shift.workAreaLabel;
    } else {
      return "Unbekannte Abteilung";
    }
  }

  String get locationLabel {
    if (shift != null) {
      return shift.locationLabel;
    } else {
      return "Unbekannter Ort";
    }
  }

  DocumentReference get shiftRef {
    if (shift != null) {
      return shift.shiftRef;
    } else {
      return vote.shiftRef;
    }
  }

  bool hasShift() => shift != null;

  bool hasVote() => vote != null;
}

class ShiftVoteHolder {
  final List<ShiftVote> _shiftVotes = <ShiftVote>[];

  int get length => _shiftVotes.length;

  bool get isEmpty => _shiftVotes.isEmpty;

  List<ShiftVote> get shiftVotes => _shiftVotes;

  void clear() {
    _shiftVotes.clear();
  }

  ShiftVote operator [](int index) {
    return _shiftVotes[index];
  }

  void addVote(Vote vote) {
    final shiftVote = _findByShiftRef(vote.shiftRef);
    if (shiftVote == null) {
      _shiftVotes.add(ShiftVote(vote: vote));
    } else {
      shiftVote.vote = vote;
    }
  }

  void addVoteFromSnapshot(DocumentSnapshot document) {
    addVote(Vote.fromSnapshot(document));
  }

  void modifyVoteFromSnapshot(DocumentSnapshot document) {
    // FIXME wenn sich bid.shiftref ändert, dann muss das entsprechend berücksichtigt werden
    // eventuell bid via bidRef vorher entfernen
    addVote(Vote.fromSnapshot(document));
  }

  void addShift(Shift shift) {
    final shiftVote = _findByShiftRef(shift.shiftRef);
    if (shiftVote == null) {
      _shiftVotes.add(ShiftVote(shift: shift));
    } else {
      shiftVote.shift = shift;
    }
  }

  void modifyShift(Shift shift) {
    addShift(shift);
  }

  void removeVote(Vote vote) {
    final shiftVote = _findByVoteRef(vote.selfRef);
    if (shiftVote != null) {
      shiftVote.vote = null;
      removeShiftVoteIfEmpty(shiftVote);
    }
  }

  void removeShift(Shift shift) {
    final shiftVote = _findByShiftRef(shift.shiftRef);
    if (shiftVote != null) {
      shiftVote.shift = null;
      removeShiftVoteIfEmpty(shiftVote);
    }
  }

  void removeVoteFromSnapshot(DocumentSnapshot document) {
    removeVote(Vote.fromSnapshot(document));
  }

  ShiftVote _findByShiftRef(DocumentReference shiftRef) {
    return _shiftVotes.firstWhere((shiftVote) => shiftVote.shiftRef.path == shiftRef.path, orElse: () => null);
  }

  ShiftVote _findByVoteRef(DocumentReference voteRef) {
    return _shiftVotes.firstWhere((shiftVote) => shiftVote.hasVote() && shiftVote.vote.selfRef.path == voteRef.path,
        orElse: () => null);
  }

  void removeShiftVoteIfEmpty(ShiftVote shiftVote) {
    if (!shiftVote.hasVote() && !shiftVote.hasShift()) {
      _shiftVotes.remove(shiftVote);
    }
  }
}
