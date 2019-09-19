import "package:angular/angular.dart";
import "package:angular_components/angular_components.dart";
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import "package:blaulichtplaner/src/authentication/authentication.dart";
import 'package:blaulichtplaner/src/routes.dart';

class Login {
  String email;
  String password;

  bool valid() {
    return email != null && email.length > 1 && password != null && password.length > 1;
  }
}

@Component(selector: "blp-welcome", templateUrl: "welcome_component.html", directives: [
  MaterialButtonComponent,
  MaterialSpinnerComponent,
  materialInputDirectives,
  formDirectives,
  coreDirectives
])
class WelcomeComponent implements OnActivate {
  final AuthenticationService auth;
  final Router _router;
  final Routes _routes;

  Login loginModel = Login();
  bool loading = false;
  String errorMessage = null;
  String globalErrorMessage = null;

  WelcomeComponent(this.auth, this._router, this._routes);

  registerWithEmail() {
    _router.navigate(_routes.emailRegistration.path);
  }

  login() async {
    if (loginModel.valid()) {
      resetErrorMessages();
      loading = true;
      try {
        print("login...");
        await auth.login(loginModel.email, loginModel.password);
        _router.navigate("/dashboard/overview");
      } catch (e) {
        String error = e.toString();
        if (error.contains("invalid")) {
          errorMessage = "E-Mail oder Passwort ungültig";
        }
      } finally {
        loading = false;
      }
    } else {
      errorMessage = "Bitte E-Mail und Passwort eingeben!";
    }
  }

  void resetErrorMessages() {
    errorMessage = null;
    globalErrorMessage = null;
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    String errorType = current.queryParameters["error"];
    if (errorType != null) {
      if (errorType == "notVerified") {
        globalErrorMessage = "Sie haben Ihre E-Mail Adresse noch nicht bestätigt. Bitte prüfen Sie Ihr E-Mail Postfach";
      }
    }
  }
}
