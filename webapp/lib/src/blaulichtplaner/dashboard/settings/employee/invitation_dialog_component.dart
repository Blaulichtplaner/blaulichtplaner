import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:firebase/firestore.dart';

class InvitationModel {
  String email;
  String invitationText;
  DocumentReference employeeRef;
}

@Component(
    selector: "blp-invitation-dialog",
    templateUrl: "invitation_dialog_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives],
    providers: [])
class InvitationDialogComponent {
  InvitationModel invitationModel = InvitationModel();

  @Input()
  DocumentReference employeeRef;

  final _cancel = new StreamController<void>();

  @Output()
  Stream<void> get onCancel => _cancel.stream;

  cancel() {
    _cancel.add(null);
  }

  final _invite = new StreamController<InvitationModel>();

  @Output()
  Stream<InvitationModel> get onInvite => _invite.stream;

  invite() {
    invitationModel.employeeRef = employeeRef;
    _invite.add(invitationModel);
  }
}
