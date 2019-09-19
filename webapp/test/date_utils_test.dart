import 'package:angular_components/model/date/date.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/date_utils.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import "package:test/test.dart";


void main() {
  test("extractWorkingHours", () {
    final startDate = new DateTime(2018, 1, 20, 10, 0, 0);
    final endDate = new DateTime(2018, 1, 20, 19, 0, 0);

    final workingHours = DateTimeUtils.extractWorkingHours(startDate, endDate);

    expect(workingHours.from, equals(new DateTime(1970, DateTime.january, 1, 10, 0)));
    expect(workingHours.to, equals(new DateTime(1970, DateTime.january, 1, 19, 0)));
  });

  test("dateTimeWithEndTime", () {
    WorkingHours workingHours = new WorkingHours.fromTo(
        new DateTime(1970, DateTime.january, 1, 10, 0), new DateTime(1970, DateTime.january, 1, 19, 0));

    final resultDateTime = DateTimeUtils.dateTimeWithEndTime(Date(2018, 8, 4), workingHours);
    expect(resultDateTime, equals(new DateTime(2018, 8, 4, 19, 0)));
  });

  test("copy shift", () {
    final workingHours = WorkingHours.fromTo(DateTime(2018, 8, 7, 19), DateTime(2018,8,8,7));
    final shiftDate = Date(2018, 8, 8);

    final startTime = DateTimeUtils.dateTimeWithTimeFrom(shiftDate, workingHours.from);
    final endTime = DateTimeUtils.dateTimeWithEndTime(shiftDate, workingHours);
    
    expect(startTime.day, 8);
    expect(startTime.hour, 19);
    expect(endTime.day, 9);
    expect(endTime.hour, 7);
    
  });
}
