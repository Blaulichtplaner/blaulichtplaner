class NewUserData {
  String uid;
  String firstName;
  String lastName;
  String email;
  DateTime termsAccepted;
  DateTime privacyPolicyAccepted;

  toMap() {
    Map<String, dynamic> result = {};
    result["firstName"] = firstName;
    result["lastName"] = lastName;
    result["email"] = email;
    result["termsAccepted"] = termsAccepted;
    result["privacyPolicyAccepted"] = privacyPolicyAccepted;
    return result;
  }
}
