import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/api/api_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/location_access_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workarea_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/routes.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'package:blaulichtplaner/src/authentication/authentication.dart';

@Component(
  selector: 'blp-app',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, coreDirectives, routerDirectives],
  providers: [
    materialProviders,
    ClassProvider(ApiService),
    ClassProvider(Client, useClass: BrowserClient),
    ClassProvider(FirebaseService),
    ClassProvider(WorkAreaService),
    ClassProvider(LocationAccessService)
  ],
)
class AppComponent implements OnInit {
  final UserService _userService;
  final AuthenticationService _auth;
  final Router _router;
  final Routes routes;

  AppComponent(this._userService, this._router, this.routes, this._auth);

  @override
  void ngOnInit() {
    print("onInit AppComponent");
/*    _userService.getUser().then((value) async {
      if (value.isLoggedIn()) {
        try {
          print("get userInfo");
          await _userService.userInfo(value.uid);
          print("current route: ${_router.current}");
          if (_router.current == null || _router.current.toUrl().isEmpty) {
            print("navigate to dashboard");
            final result = await _router.navigate("/dashboard/overview");
            print("/dashboard/overview - ${result}");
          } else {
            String currentRoute = _router.current.toUrl();
            print("currentRoute [${currentRoute}]");
          }
        } on RegistrationUnfinished {
          print("registration unfinished");
          _auth.signOut();
        }
      } else {
        _router.navigate("/welcome");
      }
    });*/
  }
}
