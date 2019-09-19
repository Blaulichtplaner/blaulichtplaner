class AvailabilityStatus {
  String status;
  String description;

  AvailabilityStatus(this.status, this.description);
}

class SimpleDateRange {
  final DateTime from;
  final DateTime to;
  final String locationPath;

  SimpleDateRange(this.from, this.to, this.locationPath);
}


class AvailabilityService {
  AvailabilityStatus checkTimes(List<SimpleDateRange> shiftDateRanges, SimpleDateRange dateRange) {
    if (shiftDateRanges.isEmpty) {
      return AvailabilityStatus("available", null);
    } else {
      SimpleDateRange directlyBefore = null;
      SimpleDateRange directlyAfter = null;
      SimpleDateRange overlapping = null;
      for (SimpleDateRange shiftDateRange in shiftDateRanges) {
        DateTime shiftFrom = shiftDateRange.from;
        DateTime shiftTo = shiftDateRange.to;
        if (shiftFrom.isAtSameMomentAs(dateRange.to)) {
          directlyBefore = shiftDateRange;
        } else if (shiftTo.isAtSameMomentAs(dateRange.from)) {
          directlyAfter = shiftDateRange;
        } else {
          if (shiftFrom.isBefore(dateRange.from) && shiftTo.isAfter(dateRange.to)) {
            overlapping = shiftDateRange; // within
          } else if (shiftFrom.isAfter(dateRange.from) && shiftTo.isBefore(dateRange.to)) {
            overlapping = shiftDateRange; // total
          } else if (shiftFrom.isAfter(dateRange.from) && shiftFrom.isBefore(dateRange.to)) {
            overlapping = shiftDateRange; // overlap from
          } else if (shiftTo.isAfter(dateRange.from) && shiftTo.isBefore(dateRange.to)) {
            overlapping = shiftDateRange; // overlap to
          } else if (shiftTo.isAtSameMomentAs(dateRange.to) || shiftFrom.isAtSameMomentAs(dateRange.from)) {
            overlapping = shiftDateRange; // overlap start or end
          }
        }
      }
      if (overlapping != null) {
        return AvailabilityStatus("busy", "Überlappender Dienst vorhanden");
      } else if (directlyBefore != null || directlyAfter != null) {
        SimpleDateRange dateRangeInQuestion = directlyBefore != null ? directlyBefore : directlyAfter;
        if (dateRangeInQuestion.locationPath == dateRange.locationPath) {
          return AvailabilityStatus("node", "Unmittelbarer Dienst am selben Standort");
        } else {
          return AvailabilityStatus("busy", "Unmittelbarer Dienst am anderen Standort");
        }
      } else {
        return AvailabilityStatus("available", "Verfügbar");
      }
    }
  }
}
