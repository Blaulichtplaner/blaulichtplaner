import 'package:angular_components/model/ui/display_name.dart';

abstract class EmployeePath extends HasUIDisplayName {
  String get path;
}

class SelectablePath implements EmployeePath {
  final String path;
  final String uiDisplayName;

  SelectablePath(this.path, this.uiDisplayName);

  @override
  bool operator ==(Object other) => other is EmployeePath && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
