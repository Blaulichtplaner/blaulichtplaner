import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/availability_service.dart';
import "package:test/test.dart";

void main() {
  final AvailabilityService availabilityService = AvailabilityService();

  _createDateRange(DateTime from, DateTime to, {String locationPath}) {
    if (locationPath == null) {
      return SimpleDateRange(from, to, "");
    } else {
      return SimpleDateRange(from, to, locationPath);
    }
  }

  test("check available", () {
    final result = availabilityService.checkTimes([], _createDateRange(DateTime.now(), DateTime.now()));
    expect(result.status, "available");
  });

  test("check from range", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19))],
        _createDateRange(DateTime(2018, 9, 23, 19), DateTime(2018, 9, 24, 7)));
    expect(result.status, "node");
  });

  test("check to range", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19))],
        _createDateRange(DateTime(2018, 9, 24, 19), DateTime(2018, 9, 25, 7)));
    expect(result.status, "node");
  });

  test("check from and to range", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 10, 24, 7), DateTime(2018, 10, 24, 19)),
        _createDateRange(DateTime(2018, 10, 24, 19), DateTime(2018, 10, 25, 7))],
        _createDateRange(DateTime(2018, 10, 23, 19), DateTime(2018, 10, 24, 7)));
    expect(result.status, "node");
  });


  test("check directly after different location", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19), locationPath: "abc")],
        _createDateRange(DateTime(2018, 9, 24, 19), DateTime(2018, 9, 25, 7), locationPath: "def"));
    expect(result.status, "busy");
  });

  test("check overlap within", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19))],
        _createDateRange(DateTime(2018, 9, 24, 9), DateTime(2018, 9, 24, 18)));
    expect(result.status, "busy");
  });

  test("check overlap total", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19))],
        _createDateRange(DateTime(2018, 9, 24, 6), DateTime(2018, 9, 24, 20)));
    expect(result.status, "busy");
  });

  test("check overlap from", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19))],
        _createDateRange(DateTime(2018, 9, 24, 6), DateTime(2018, 9, 24, 10)));
    expect(result.status, "busy");
  });

  test("check overlap to", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19))],
        _createDateRange(DateTime(2018, 9, 24, 18), DateTime(2018, 9, 24, 20)));
    expect(result.status, "busy");
  });

  test("check overlap same shift", () {
    final result = availabilityService.checkTimes(
        [_createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19))],
        _createDateRange(DateTime(2018, 9, 24, 7), DateTime(2018, 9, 24, 19)));
    expect(result.status, "busy");
  });

  test("check next day", () {
    final result = availabilityService.checkTimes([_createDateRange(DateTime(2018, 9, 5, 7), DateTime(2018, 9, 5, 19))],
        _createDateRange(DateTime(2018, 9, 6, 7), DateTime(2018, 9, 6, 7)));
    expect(result.status, "available");
  });
}
