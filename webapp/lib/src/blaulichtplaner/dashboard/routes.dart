import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/dashboard_overview_component.template.dart'
    as dashboardOverviewCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/evaluation/evaluation_component.template.dart'
    as evaluationCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/invitation/invitation_component.template.dart'
    as invitationCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/route_paths.dart' as paths;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/settings_component.template.dart' as settingsCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/shiftplan_component.template.dart'
    as shiftplanCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shifts/shift_list_component.template.dart' as shiftListCt;

@Injectable()
class Routes {
  static final _dashboardOverviewCt = new RouteDefinition(
      routePath: paths.dashboardOverview,
      component: dashboardOverviewCt.DashboardOverviewComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _settingsCt = new RouteDefinition(
      routePath: paths.settings, component: settingsCt.SettingsComponentNgFactory, additionalData: [UserRole.user]);

  static final _shiftplanCt = new RouteDefinition(
      routePath: paths.shiftplan, component: shiftplanCt.ShiftplanComponentNgFactory, additionalData: [UserRole.user]);

  static final _evaluationCt = new RouteDefinition(
      routePath: paths.evaluation,
      component: evaluationCt.EvaluationComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _invitationCt =
      new RouteDefinition(routePath: paths.invitation, component: invitationCt.InvitationComponentNgFactory);

  static final _shiftListCt =
      new RouteDefinition(routePath: paths.shifts, component: shiftListCt.ShiftListComponentNgFactory);

  final List<RouteDefinition> all = [
    _dashboardOverviewCt,
    _settingsCt,
    _shiftplanCt,
    _evaluationCt,
    _invitationCt,
    _shiftListCt
  ];
}
