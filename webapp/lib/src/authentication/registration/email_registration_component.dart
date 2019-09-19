import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/authentication/registration/registration_component.dart';
import 'package:blaulichtplaner/src/authentication/registration/registration_service.dart';
import 'package:blaulichtplaner/src/routes.dart';
import 'package:firebase/firebase.dart';

class EmailRegistration extends Registration {
  String password;
  String password2;

  bool passwordValid() {
    return password.length >= 8 && password == password2;
  }
}

@Component(
    selector: "blp-email-registration",
    templateUrl: "email_registration_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives],
    providers: [RegistrationService])
class EmailRegistrationComponent implements OnActivate {
  EmailRegistration registration = EmailRegistration();

  final AuthenticationService _auth;
  final RegistrationService _registrationService;
  final UserService _userService;
  final Router _router;
  final Routes _routes;
  var hideErrorMessage = true;
  String errorMessage;
  bool loading = false;

  @ViewChild("registerForm")
  NgForm registerForm;

  EmailRegistrationComponent(this._userService, this._registrationService, this._router, this._auth, this._routes);

  @override
  void onActivate(_, RouterState current) async {
    _auth.signOut();
  }

  register() async {
    hideErrorMessage = true;
    final termsValid = registration.privacy && registration.terms;
    if (termsValid) {
      if (registerForm.valid) {
        if (registration.passwordValid()) {
          try {
            loading = true;
            UserCredential userCredential = await _auth.registerWithEmail(registration.email, registration.password);
            if (!userCredential.user.emailVerified) {
              print("Sending email verification");
              userCredential.user.sendEmailVerification();
            }
            final verificationEmailSend = !userCredential.user.emailVerified;
            final BlpUser user = await _userService.getUser();
            if (user.isLoggedIn()) {
              await _registrationService.register(userCredential.user.uid, registration);
              _router.navigate(_routes.registrationComplete.path,
                  NavigationParams(queryParameters: {"verificationEmailSend": verificationEmailSend.toString()}));
            } else {
              print("Benutzer ist nicht eingeloggt");
            }
          } catch (e) {
            if (e.toString().contains("already in use")) {
              _showError(
                  "Die E-Mail Adresse wird bereits verwendet. Bitte loggen Sie sich mit dieser E-Mail Adresse ein. Benutzen Sie bitte die Funktion 'Passwort vergessen', falls Sie Ihr Passwort nicht mehr wissen.");
            } else {
              _showError(e.toString());
            }
          } finally {
            loading = false;
          }
        } else {
          registration.password = "";
          registration.password2 = "";
          _showError(
              "Passwort Wiederholung stimmt nicht mit Ihrem Passwort überein. Bitte geben Sie das Passwort erneut ein.");
        }
      } else {
        _showError("Bitte füllen Sie alle Felder aus.");
      }
    } else {
      _showError("Sie müssen die AGBs und die Datenschutzbestimmungen für Blaulichtplaner akzeptieren.");
    }
  }

  void _showError(String message) {
    errorMessage = message;
    hideErrorMessage = false;
  }
}
