import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/route_paths.dart';

final dashboardOverview = new RoutePath(path: 'overview', parent: dashboard);
final settings = new RoutePath(path: 'settings', parent: dashboard);
final shiftplan = new RoutePath(path: 'shiftplan', parent: dashboard);
final evaluation = new RoutePath(path: 'evaluation', parent: dashboard);
final invitation = new RoutePath(path: 'invitation', parent: dashboard);
final shifts = new RoutePath(path: 'shifts', parent: dashboard);

