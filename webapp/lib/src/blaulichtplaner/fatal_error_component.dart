import "package:angular/angular.dart";
import "package:angular_components/angular_components.dart";
import 'package:angular_router/angular_router.dart';

@Component(
    selector: "blp-fatal-error",
    template: "<div>{{errorMessage}}</div>",
    directives: [MaterialButtonComponent, MaterialSpinnerComponent, materialInputDirectives, coreDirectives])
class FatalErrorComponent implements OnActivate {
  String errorMessage;

  @override
  void onActivate(RouterState previous, RouterState current) {
    String type = current.queryParameters["errorType"];
    if (type != null) {
      switch (type) {
        case "verifyEmail":
          {
            errorMessage =
            "Bitte verifizieren Sie Ihre E-Mail Adresse. Eine E-Mail mit dem Verifizierungslink wurde verschickt";
            break;
          }
        default:
          {
            errorMessage = "Unbekannter Fehler (" + type + ")";
          }
      }
    } else {
      errorMessage = "Unbekannter Fehler";
    }
  }
}
