import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/routes.dart';

@Component(
    selector: "blp-registration-complete",
    templateUrl: "registration_complete_component.html",
    directives: [coreDirectives, materialDirectives, routerDirectives])
class RegistrationCompleteComponent implements OnActivate {
  final Routes routes;
  bool verificationEmailSend = false;

  RegistrationCompleteComponent(this.routes);

  @override
  void onActivate(RouterState previous, RouterState current) {
    verificationEmailSend = current.queryParameters["verificationEmailSend"] == "true";
  }
}
