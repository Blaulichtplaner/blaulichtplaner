import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/api/api_service.dart';
import 'package:blaulichtplaner/src/authentication/registration/registration_component.dart';
import 'package:blaulichtplaner/src/domain/user.dart';

@Injectable()
class RegistrationService {
  final ApiService apiService;

  RegistrationService(this.apiService);

  Future<bool> isRegistrationPossible(String userId) async {
    bool userRegistered = await apiService.isUserRegistered(userId);
    return !userRegistered;
  }

  register(String userId, Registration registration) async {
    NewUserData newUserData = new NewUserData();
    newUserData.uid = userId;
    newUserData.firstName = registration.firstName;
    newUserData.lastName = registration.lastName;
    newUserData.email = registration.email;
    if (registration.privacy && registration.terms) {
      newUserData.privacyPolicyAccepted = new DateTime.now();
      newUserData.termsAccepted = new DateTime.now();
      return apiService.addUser(newUserData);
    } else {
      return null;
    }
  }
}
