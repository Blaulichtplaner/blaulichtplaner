import 'package:angular_components/model/selection/selection_model.dart';
import 'package:angular_components/model/ui/display_name.dart';
import 'package:firebase/src/firestore.dart';

class Employee implements HasUIDisplayName {
  String title;
  String firstName;
  String lastName;
  DateTime birthday;
  String areaOfExpertise;
  List<String> qualifications;
  bool additionalTitle;
  String origin;

  String street;
  String postalCode;
  String city;

  String bankName;
  String iban;
  String bic;
  DocumentReference userRef;

  bool invitationPending = false;

  Employee.fromSnapshot(DocumentSnapshot snapshot) {
    title = snapshot.get("title");
    firstName = snapshot.get("firstName");
    lastName = snapshot.get("lastName");
    //birthday = snapshot.get("birthday");
    areaOfExpertise = snapshot.get("areaOfExpertise");
    qualifications = List<String>.from(snapshot.get("qualifications"));
    additionalTitle = snapshot.get("additionalTitle");
    origin = snapshot.get("origin");
    street = snapshot.get("street");
    postalCode = snapshot.get("postalCode");
    city = snapshot.get("city");
    bankName = snapshot.get("bankName");
    iban = snapshot.get("iban");
    bic = snapshot.get("bic");
    userRef = snapshot.get("userRef");
    invitationPending = snapshot.get("invitationPending") != null ? snapshot.get("invitationPending") : false;
  }

  bool get hasUser => userRef != null;

  @override
  String get uiDisplayName {
    if (title != null && title.isNotEmpty) {
      return title + " " + firstName + " " + lastName;
    } else {
      return firstName + " " + lastName;
    }
  }
}

class EmployeeModel {
  SelectionModel<String> title;
  String firstName;
  String lastName;
  String birthday;
  String areaOfExpertise;
  List qualifications = [];
  bool additionalTitle;
  String origin;

  String street;
  String postalCode;
  String city;

  String bankName;
  String iban;
  String bic;

  EmployeeModel.empty() {
    title = SelectionModel.single();
  }

  void updateWithSnapshot(DocumentSnapshot snapshot) {
    title = SelectionModel.single(selected: snapshot.get("title"));
    firstName = snapshot.get("firstName");
    lastName = snapshot.get("lastName");
    //birthday = snapshot.get("birthday");
    areaOfExpertise = snapshot.get("areaOfExpertise");
    qualifications = List<String>.from(snapshot.get("qualifications"));
    additionalTitle = snapshot.get("additionalTitle");
    origin = snapshot.get("origin");
    street = snapshot.get("street");
    postalCode = snapshot.get("postalCode");
    city = snapshot.get("city");
    bankName = snapshot.get("bankName");
    iban = snapshot.get("iban");
    bic = snapshot.get("bic");
  }

  EmployeeModel.fromEmployee(Employee employee) {
    title = SelectionModel.single(selected: employee.title);
    firstName = employee.firstName;
    lastName = employee.lastName;
    areaOfExpertise = employee.areaOfExpertise;
    qualifications = employee.qualifications;
    additionalTitle = employee.additionalTitle;
    origin = employee.origin;
    street = employee.street;
    postalCode = employee.postalCode;
    city = employee.city;
    bankName = employee.bankName;
    iban = employee.iban;
    bic = employee.bic;
  }

  Map<String, Object> toMap() {
    Map<String, Object> data = {};
    data["title"] = title.selectedValues.isNotEmpty ? title.selectedValues.first : null;
    data["firstName"] = firstName;
    data["lastName"] = lastName;
    //data["birthday"] = birthday;
    data["areaOfExpertise"] = areaOfExpertise;
    data["qualifications"] = qualifications;
    data["additionalTitle"] = additionalTitle;
    data["origin"] = origin;
    data["street"] = street;
    data["postalCode"] = postalCode;
    data["city"] = city;
    data["bankName"] = bankName;
    data["iban"] = iban;
    data["bic"] = bic;
    return data;
  }
}
