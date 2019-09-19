import 'package:angular/angular.dart';

@Pipe('duration')
class DurationPipe extends PipeTransform {
  transform(dynamic value) {
    if (value != null) {
      final durationMinutes = value is int ? value : int.parse(value);
      final hours = (durationMinutes / 60).truncate();
      final minutes = durationMinutes - (hours * 60);
      if (minutes > 0) {
        return "${hours}h ${minutes}m";
      } else {
        return "${hours}h";
      }
    } else {
      return "-";
    }
  }
}
