import 'package:angular_components/model/date/date.dart';
import 'package:blaulichtplaner/src/domain/models.dart';

class DateTimeUtils {
  static DateTime dateTimeWithTimeFrom(Date dateTime, DateTime otherDateTime) {
    return new DateTime(
        dateTime.year, dateTime.month, dateTime.day, otherDateTime.hour, otherDateTime.minute, otherDateTime.second);
  }

  static dateTimeWithDateFrom(DateTime dateTime, Date otherDate) {
    return new DateTime(
        otherDate.year, otherDate.month, otherDate.day, dateTime.hour, dateTime.minute, dateTime.second);
  }

  static DateTime dateTimeWithEndTime(Date date, WorkingHours workingHours) {
    if (workingHours.from.isAfter(workingHours.to) || workingHours.from.isAtSameMomentAs(workingHours.to)) {
      date = date.add(days: 1);
    }
    return DateTimeUtils.dateTimeWithTimeFrom(date, workingHours.to);
  }

  static WorkingHours extractWorkingHours(DateTime startDate, DateTime endDate) {
    final from = new DateTime(1970, DateTime.january, 1, startDate.hour, startDate.minute);
    final to = new DateTime(1970, DateTime.january, 1, endDate.hour, endDate.minute);
    return new WorkingHours.fromTo(from, to);
  }

  static isSameDate(Date date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
