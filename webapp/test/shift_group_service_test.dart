import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/shift_group_service.dart';
import 'package:mockito/mockito.dart';
import "package:test/test.dart";

class ShiftVoteMock extends Mock implements ShiftVoteInterface {}

void main() {
  ShiftGroupService service = ShiftGroupService();

  ShiftVoteInterface vote1a = ShiftVoteMock();
  when(vote1a.from).thenAnswer((inv) => DateTime(2018, 11, 1, 7));
  when(vote1a.to).thenAnswer((inv) => DateTime(2018, 11, 1, 19));
  when(vote1a.locationLabel).thenAnswer((inv) => "abc");
  when(vote1a.workAreaLabel).thenAnswer((inv) => "Notdienst");
  ShiftVoteInterface vote1b = ShiftVoteMock();
  when(vote1b.from).thenAnswer((inv) => DateTime(2018, 11, 1, 19));
  when(vote1b.to).thenAnswer((inv) => DateTime(2018, 11, 2, 7));
  when(vote1b.locationLabel).thenAnswer((inv) => "abc");
  when(vote1b.workAreaLabel).thenAnswer((inv) => "Notdienst");

  ShiftVoteInterface vote2 = ShiftVoteMock();
  when(vote2.from).thenAnswer((inv) => DateTime(2018, 11, 2, 7));
  when(vote2.to).thenAnswer((inv) => DateTime(2018, 11, 2, 19));
  when(vote2.locationLabel).thenAnswer((inv) => "abc");
  when(vote2.workAreaLabel).thenAnswer((inv) => "Notdienst");

  ShiftVoteInterface vote3 = ShiftVoteMock();
  when(vote3.from).thenAnswer((inv) => DateTime(2018, 11, 2, 7));
  when(vote3.to).thenAnswer((inv) => DateTime(2018, 11, 2, 19));
  when(vote3.locationLabel).thenAnswer((inv) => "xyz");
  when(vote3.workAreaLabel).thenAnswer((inv) => "Notdienst");

  ShiftVoteInterface vote4 = ShiftVoteMock();
  when(vote4.from).thenAnswer((inv) => DateTime(2018, 11, 3, 7));
  when(vote4.to).thenAnswer((inv) => DateTime(2018, 11, 3, 19));
  when(vote4.locationLabel).thenAnswer((inv) => "xyz");
  when(vote4.workAreaLabel).thenAnswer((inv) => "Notdienst");

  ShiftVoteInterface vote5 = ShiftVoteMock();
  when(vote5.from).thenAnswer((inv) => DateTime(2018, 11, 3, 7));
  when(vote5.to).thenAnswer((inv) => DateTime(2018, 11, 3, 19));
  when(vote5.locationLabel).thenAnswer((inv) => "abc");
  when(vote5.workAreaLabel).thenAnswer((inv) => "Notdienst");

  List<ShiftVoteInterface> shifts = [vote4, vote3, vote1a, vote1b, vote2, vote5];

  test("createShiftGroups", () {
    
    service.injectShiftGroups(shifts);
    
  });

  test("group shifts", () {

    List<ShiftDayContainer> groupedList = service.groupShiftVotes(shifts);

    expect(groupedList.length, 3);

    ShiftDayContainer container1 = groupedList[0];
    ShiftDayContainer container2 = groupedList[1];
    ShiftDayContainer container3 = groupedList[2];

    expect(container1.day.day, 1);
    expect(container2.day.day, 2);
    expect(container3.day.day, 3);

    ShiftVoteInterface sv1 = container2.shiftVotes[0];
    ShiftVoteInterface sv2 = container2.shiftVotes[1];
    expect(sv1.locationLabel, "abc");
    expect(sv2.locationLabel, "xyz");
  });
}
