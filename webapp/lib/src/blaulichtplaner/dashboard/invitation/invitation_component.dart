import 'dart:async';

import "package:angular/angular.dart";
import "package:angular_components/angular_components.dart";
import 'package:angular_router/angular_router.dart';
import "package:blaulichtplaner/src/authentication/authentication.dart";
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/invitation/invitation_confirm_component.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/utils/loadable.dart';

class Invitation {
  DocumentReference invitationRef;
  String companyLabel;
  DocumentReference companyRef;
  DocumentReference employeeRef;
  String invitedBy;
  

  Invitation.fromSnapshot(DocumentSnapshot snapshot) {
    invitationRef = snapshot.ref;
    companyLabel = snapshot.get("companyLabel");
    companyRef = snapshot.get("companyRef");
    employeeRef = snapshot.get("employeeRef");
    invitedBy = snapshot.get("invitedBy");
  }
}

@Component(
    selector: "blp-invitation",
    templateUrl: "invitation_component.html",
    directives: [MaterialButtonComponent, MaterialSpinnerComponent, coreDirectives, InvitationConfirmComponent])
class InvitationComponent extends Object with Loadable implements OnActivate, OnDeactivate {
  final AuthenticationService auth;
  final UserService userService;
  final FirebaseService _firebaseService;
  StreamSubscription<QuerySnapshot> subscription;

  List<Invitation> invitations = [];

  InvitationComponent(this.auth, this.userService, this._firebaseService);

  void onActivate(_, RouterState current) async {
    startLoading();
    String invitationId = current.parameters["invitationId"];
    final user = await userService.getUser();
    subscription = await _firebaseService.firestore
        .collection("/invitations")
        .where("email", "==", user.email)
        .where("accepted", "==", false)
        .onSnapshot
        .listen((snapshotEvent) {
      for (final docChange in snapshotEvent.docChanges()) {
        if (docChange.type == "added") {
          invitations.add(Invitation.fromSnapshot(docChange.doc));
        } else if (docChange.type == "modified") {
          DocumentReference refToRemove = docChange.doc.ref;
          invitations.removeWhere((invite) => invite.invitationRef.path == refToRemove.path);
          invitations.add(Invitation.fromSnapshot(docChange.doc));
        } else if (docChange.type == "removed") {
          DocumentReference refToRemove = docChange.doc.ref;
          invitations.removeWhere((invite) => invite.invitationRef.path == refToRemove.path);
        }
      }
      finishLoading();
    });
  }

  @override
  void onDeactivate(RouterState previous, RouterState current) {
    subscription?.cancel();
    subscription = null;
  }
}
