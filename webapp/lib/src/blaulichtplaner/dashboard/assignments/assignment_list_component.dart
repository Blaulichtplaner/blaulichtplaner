import "package:angular/angular.dart";
import "package:angular_components/angular_components.dart";
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/datetime_utils.dart';
import 'package:firebase/firestore.dart';

class Assignment {
  DocumentReference selfRef;
  DateTime from;
  DateTime to;
  String locationLabel;
  String publicNote;
  String workAreaLabel;
  bool evaluated;
  String durationLabel;

  Assignment.fromSnapshot(DocumentSnapshot snapshot) {
    selfRef = snapshot.ref;
    from = snapshot.get("from");
    to = snapshot.get("to");
    workAreaLabel = snapshot.get("workAreaLabel");
    publicNote = snapshot.get("publicNote");
    locationLabel = snapshot.get("locationLabel");
    evaluated = snapshot.get("evaluated");
    durationLabel = shiftDurationLabel(from, to);
  }
}

@Component(
    selector: "blp-assignment-list",
    templateUrl: "assignment_list_component.html",
    directives: [materialDirectives, coreDirectives],
    pipes: [DatePipe])
class AssignmentListComponent implements OnInit {
  final FirebaseService _firebaseService;
  final UserService _userService;
  String shiftsTitle = "Kommende Dienste";

  List<Assignment> assignments = [];
  bool upcomingShifts = true;
  bool loading = true;

  AssignmentListComponent(this._firebaseService, this._userService);

  _initDataListeners(List<DocumentReference> employeeRoles) async {
    final firestore = _firebaseService.firestore;
    if (employeeRoles.isEmpty) {
      loading = false;
    } else {
      try {
        for (final role in employeeRoles) {
          Query query =
              firestore.collection("assignments").where("status", "==", "public").where("employeeRef", "==", role);
          if (upcomingShifts) {
            query = query.where("to", ">=", DateTime.now()).orderBy("to");
          } else {
            query = query.where("evaluated", "==", false).where("to", "<=", DateTime.now()).orderBy("to", "desc");
          }
          final querySnapshot = await query.get();
          querySnapshot.forEach((snapshot) {
            assignments.add(Assignment.fromSnapshot(snapshot));
          });
          assignments.sort((s1, s2) => s1.from.compareTo(s2.from));
          loading = false;
        }
      } catch (e) {
        print("ERROR: $e");
      }
    }
  }

  _initAndReadShifts() async {
    BlpUser user = await _userService.getUser();
    final firestore = _firebaseService.firestore;

    final query =
        await firestore.collection("users").doc(user.uid).collection("roles").where("type", "==", "employee").get();
    List<DocumentReference> employeeRoles = [];

    query.forEach((snapshot) {
      employeeRoles.add(snapshot.get("reference"));
    });
    _initDataListeners(employeeRoles);
  }

  @override
  void ngOnInit() {
    _initAndReadShifts();
  }
}
