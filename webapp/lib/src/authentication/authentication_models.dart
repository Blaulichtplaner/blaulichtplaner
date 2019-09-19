import 'package:firebase/firestore.dart';

enum UserRole { user, admin, companyManager, locationManager }

class Role {
  DocumentReference reference;
  DocumentReference companyRef;
  String companyLabel;
  String role;
  String label;

  Role.fromSnapshot(DocumentSnapshot snapshot) {
    reference = snapshot.get("reference");
    role = snapshot.get("role");
    label = snapshot.get("label");
    companyRef = snapshot.get("companyRef");
    companyLabel = snapshot.get("companyLabel");
  }
}
