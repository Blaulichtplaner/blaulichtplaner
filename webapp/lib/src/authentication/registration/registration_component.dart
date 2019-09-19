import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/authentication/registration/registration_service.dart';
import 'package:blaulichtplaner/src/routes.dart';

class Registration {
  String firstName = "";
  String lastName = "";
  String email = "";
  bool terms = false;
  bool privacy = false;
}

@Component(
    selector: "blp-registration",
    templateUrl: "registration_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives],
    providers: [RegistrationService])
class RegistrationComponent implements OnActivate {
  Registration registration = new Registration();

  final AuthenticationService _auth;
  final RegistrationService _registrationService;
  final UserService _userService;
  final Router _router;
  final Routes _routes;
  var termsValid = true;
  var registrationPossible = false;
  var userCanRegister = false;

  @ViewChild("registerForm")
  NgForm registerForm;

  RegistrationComponent(this._userService, this._registrationService,
      this._router, this._auth, this._routes);

  @override
  void onActivate(_, RouterState current) async {
    final String displayName = current.queryParameters["displayName"];
    var split = displayName.split(" ");

    if (split.length > 0) {
      if (split.length > 1) {
        registration.firstName = split[0];
        registration.lastName = split[1];
      } else {
        registration.firstName = split[0];
      }
    }
    registration.email = current.queryParameters["email"];

    final BlpUser user = await _userService.getUser();
    
    registrationPossible = user.isLoggedIn();
    if (registrationPossible) {
      registrationPossible = await _registrationService
          .isRegistrationPossible(user.uid);
    }
  }

  register() async {
    termsValid = registration.privacy && registration.terms;
    if (registerForm.valid && termsValid) {
      final BlpUser user = await _userService.getUser();
      
      if (user.isLoggedIn()) {
        await _registrationService.register(
            user.uid, registration);
        await _auth.signOut();
        _router.navigate(_routes.registrationComplete.path);
      }
    }
  }
}
