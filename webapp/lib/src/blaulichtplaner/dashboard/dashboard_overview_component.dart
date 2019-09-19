import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/assignments/assignment_list_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/employee/employee_select_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';

@Component(
    selector: 'blp-dashboard-overview',
    templateUrl: 'dashboard_overview_component.html',
    directives: [AssignmentListComponent, coreDirectives, EmployeeSelectComponent])
class DashboardOverviewComponent implements OnInit {
  final FirebaseService _firebaseService;
  final UserService _userService;

  bool showIntro = false;

  DashboardOverviewComponent(this._firebaseService, this._userService);

  @override
  Future ngOnInit() async {
    final user = await _userService.getUser();
    final query = await _firebaseService.firestore.collection("users").doc(user.uid).collection("roles").get();
    showIntro = query.empty;
  }
}
