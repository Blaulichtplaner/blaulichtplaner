import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';

import 'route_paths.dart' as paths;
import 'shiftplan_overview_component.template.dart' as shiftplanOverviewCt;

@Injectable()
class Routes {
  static final _shiftplanOverviewCt = new RouteDefinition(
      routePath: paths.shiftplanOverview,
      component: shiftplanOverviewCt.ShiftplanOverviewComponentNgFactory,
      additionalData: [UserRole.user]);

  final List<RouteDefinition> all = [_shiftplanOverviewCt];
}
