import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/invitation/invitation_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/utils/loadable.dart';

@Component(
    selector: "blp-invitation-confirm",
    templateUrl: "invitation_confirm_component.html",
    directives: [MaterialButtonComponent, MaterialSpinnerComponent, coreDirectives])
class InvitationConfirmComponent extends Object with Loadable {
  final FirebaseService _firebaseService;
  final UserService _userService;

  @Input("invitation")
  Invitation invitation;

  InvitationConfirmComponent(this._firebaseService, this._userService);

  confirmInvitation() async {
    startLoading();
    BlpUser user = await _userService.getUser();
    DocumentReference userRef = _firebaseService.firestore.collection("users").doc(user.uid);

    QuerySnapshot querySnapshot = await userRef
        .collection("roles")
        .where("reference", "==", invitation.employeeRef)
        .where("type", "==", "employee")
        .get();
    if (querySnapshot.empty) {
      WriteBatch batch = _firebaseService.firestore.batch();
      Map<String, Object> roleData = {};
      roleData["role"] = "user";
      roleData["type"] = "employee";
      roleData["created"] = DateTime.now();
      roleData["reference"] = invitation.employeeRef;
      roleData["companyRef"] = invitation.companyRef;
      roleData["companylabel"] = invitation.companyLabel;

      Map<String, Object> invitationData = {};
      invitationData["accepted"] = true;
      invitationData["acceptedOn"] = DateTime.now();

      Map<String, Object> employeeData = {};
      employeeData["userRef"] = userRef;
      employeeData["invitationPending"] = false;

      batch
        ..set(userRef.collection("roles").doc(), roleData)
        ..update(invitation.invitationRef, data: invitationData)
        ..update(invitation.employeeRef, data: employeeData);
      
      await batch.commit();
    } else {
      print("user has already employee role");
      // TODO show error
    }

    finishLoading();
  }
}
