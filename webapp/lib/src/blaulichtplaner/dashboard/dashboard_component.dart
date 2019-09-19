import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';

import 'routes.dart';

@Component(
    selector: 'blp-dashboard',
    templateUrl: 'dashboard_component.html',
    directives: [materialDirectives, coreDirectives, routerDirectives],
    providers: const [materialProviders, ClassProvider(Routes)])
class DashboardComponent implements OnActivate {
  final AuthenticationService auth;
  final Routes routes;
  final UserService _userService;
  final ContextService contextService;
  
  BlpUser user;
  
  bool labelsVisible = true; 

  DashboardComponent(this.auth, this.routes, this._userService, this.contextService);

  @override
  void onActivate(RouterState previous, RouterState current) async {
    user = await _userService.getUser();
  }
}
