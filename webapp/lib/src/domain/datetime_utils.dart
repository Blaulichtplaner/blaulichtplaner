shiftDurationLabel(DateTime from, DateTime to) {
  final shiftDuration = to.difference(from);
  int shiftHours = shiftDuration.inHours;
  final minutesDuration = shiftDuration - Duration(hours: shiftHours);
  int shiftMinutes = minutesDuration.inMinutes;

  return shiftHours.toString() + "h" + (shiftMinutes > 0 ? (" " + shiftMinutes.toString() + "m") : "");
}
