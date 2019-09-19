import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'routes.dart';

@Component(
    selector: 'blp-settings',
    templateUrl: 'settings_component.html',
    directives: [materialDirectives, coreDirectives, routerDirectives],
    providers: const [materialProviders, const ClassProvider(Routes)])
class SettingsComponent {
  final AuthenticationService auth;
  final Routes routes;
  final UserService userService;

  SettingsComponent(
      this.auth, this.routes, this.userService);
}
