import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_manager_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart' as models;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_name_pipe.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/invitation_dialog_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/route_paths.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

@Component(
    selector: 'blp-employee-manager',
    templateUrl: 'employee_manager_component.html',
    directives: [materialDirectives, coreDirectives, InvitationDialogComponent],
    providers: [ClassProvider(EmployeeManagerService)],
    pipes: [EmployeeNamePipe])
class EmployeeManagerComponent implements OnActivate, CanReuse {
  final EmployeeManagerService _employeeManagerService;
  final FirebaseService _firebaseService;
  final UserService _userService;
  final Router _router;

  bool invitationEditorVisible;
  DocumentReference employeeRef;

  DocumentReference companyRef;
  String companyId;
  var employees = new LoadingData<TransportResult<models.Employee>>();

  EmployeeManagerComponent(this._employeeManagerService, this._router, this._firebaseService, this._userService);

  addEmployee() {
    _router.navigate(settingsEmployeeEditor.toUrl(parameters: {"companyId": companyId, "employeeId": "new"}));
  }

  selectEmployee(String employeeId) {
    _router.navigate(settingsEmployeeEditor.toUrl(parameters: {"companyId": companyId, "employeeId": employeeId}));
  }

  inviteEmployee(DocumentReference employeeRef) {
    this.employeeRef = employeeRef;
    invitationEditorVisible = true;
  }

  cancelInvitation() {
    invitationEditorVisible = false;
  }

  sendInvitation(InvitationModel invitationModel) async {
    print("send invitation");
    print(invitationModel);

    BlpUser user = await _userService.getUser();

    DocumentSnapshot snapshot = await companyRef.get();
    String companyLabel = snapshot.get("companyName");
    Map<String, Object> data = {};
    data["email"] = invitationModel.email;
    data["invitationText"] = invitationModel.invitationText;
    data["employeeRef"] = invitationModel.employeeRef;
    data["created"] = DateTime.now();
    data["companyRef"] = companyRef;
    data["companyLabel"] = companyLabel;
    data["accepted"] = false;
    data["notificationSend"] = false;
    data["invitedBy"] = user.displayName;
    data["invitedById"] = user.uid;

    DocumentReference invitationRef = await _firebaseService.firestore.collection("invitations").add(data);
    
    Map<String, Object> employeeData = {};
    employeeData["invitationPending"] = true;
    employeeData["invitationRef"] = invitationRef;
    await invitationModel.employeeRef.update(data: employeeData);
    invitationEditorVisible = false;
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    companyId = current.parameters["companyId"];
    companyRef = _firebaseService.companyReference(companyId);
    if (!isEmptyId(companyId)) {
      employees.init(_employeeManagerService.getEmployees(companyId));
    }
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
