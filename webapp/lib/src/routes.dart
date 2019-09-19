import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:blaulichtplaner/src/authentication/logout/logout_component.template.dart' as logoutCt;
import 'package:blaulichtplaner/src/authentication/registration/email_registration_component.template.dart'
    as emailRegistrationCt;
import 'package:blaulichtplaner/src/authentication/registration/registration_complete_component.template.dart'
    as registrationCompleteCt;
import 'package:blaulichtplaner/src/authentication/registration/registration_component.template.dart' as registrationCt;
import 'package:blaulichtplaner/src/authentication/welcome/welcome_component.template.dart' as welcomeCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/dashboard_component.template.dart' as dashboardCt;
import 'package:blaulichtplaner/src/blaulichtplaner/fatal_error_component.template.dart' as fatalErrorCt;
import 'package:blaulichtplaner/src/route_paths.dart' as paths;

@Injectable()
class Routes {
  static final _welcomeCt =
      new RouteDefinition(routePath: paths.welcome, component: welcomeCt.WelcomeComponentNgFactory);

  static final _dashboardCt = new RouteDefinition(
      routePath: paths.dashboard, component: dashboardCt.DashboardComponentNgFactory, additionalData: [UserRole.user]);

  static final _logoutCt = new RouteDefinition(routePath: paths.logout, component: logoutCt.LogoutComponentNgFactory);

  static final _registrationCt =
      new RouteDefinition(routePath: paths.registration, component: registrationCt.RegistrationComponentNgFactory);

  static final _registrationCompleteCt = new RouteDefinition(
      routePath: paths.registrationComplete, component: registrationCompleteCt.RegistrationCompleteComponentNgFactory);

  static final _emailRegistrationCt = new RouteDefinition(
      routePath: paths.emailRegistration, component: emailRegistrationCt.EmailRegistrationComponentNgFactory);

  static final _fatalErrorCt =
      new RouteDefinition(routePath: paths.fatalError, component: fatalErrorCt.FatalErrorComponentNgFactory);

  final welcome = _welcomeCt;
  final dashboard = _dashboardCt;
  final logout = _logoutCt;
  final registration = _registrationCt;
  final registrationComplete = _registrationCompleteCt;
  final emailRegistration = _emailRegistrationCt;
  final fatalError = _fatalErrorCt;

  final List<RouteDefinition> all = [
    _welcomeCt,
    _dashboardCt,
    _logoutCt,
    _registrationCt,
    _registrationCompleteCt,
    _emailRegistrationCt,
    _fatalErrorCt
  ];
}
