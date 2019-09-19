import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';

@Component(
    selector: 'blp-shiftplan-overview',
    templateUrl: 'shiftplan_overview_component.html',
    directives: [materialDirectives, coreDirectives, routerDirectives],
    providers: const [materialProviders])
class ShiftplanOverviewComponent {

  ShiftplanOverviewComponent() {
   print("ShiftplanOverviewComponent created"); 
   
  }
}
