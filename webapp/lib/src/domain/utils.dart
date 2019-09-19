import 'dart:async';

import 'package:angular_components/model/date/date.dart';

class LoadingData<T> {
  bool loading = true;
  List<T> _data;

  List<T> get data => _data;

  init(Future<List<T>> future) {
    loading = true;
    future.then((value) {
      _data = value;
      loading = false;
    });
  }

  bool isNotEmpty() {
    return !loading && data != null && data.isNotEmpty;
  }

  bool isEmpty() {
    return !loading && data != null && data.isEmpty;
  }
}

isEmptyId(String id) {
  return id == null || id.isEmpty || id.startsWith(":");
}

int weekNumber(Date now) {
  int today = now.weekday;

  // ISO week date weeks start on monday
  // so correct the day number
  var dayNr = (today + 6) % 7;

  // ISO 8601 states that week 1 is the week
  // with the first thursday of that year.
  // Set the target date to the thursday in the target week
  var thisMonday = now.add(days: -dayNr);
  var thisThursday = thisMonday.add(days: 3);

  // Set the target to the first thursday of the year
  // First set the target to january first
  var firstThursday = Date(now.year, DateTime.january, 1);

  if (firstThursday.weekday != (DateTime.thursday)) {
    firstThursday = Date(now.year, DateTime.january, 1 + ((4 - firstThursday.weekday) + 7) % 7);
  }

  // The weeknumber is the number of weeks between the
  // first thursday of the year and the thursday in the target week
  var x = thisThursday.asUtcTime().millisecondsSinceEpoch -
      firstThursday.asUtcTime().millisecondsSinceEpoch; // thisThursday.difference(firstThursday)
  var weekNumber = x.ceil() / 604800000; // 604800000 = 7 * 24 * 3600 * 1000

  return weekNumber.ceil() + 1;
}
