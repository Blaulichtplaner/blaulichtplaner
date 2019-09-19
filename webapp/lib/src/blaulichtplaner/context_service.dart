import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';

class SelectedElement {
  DocumentReference ref;
  String name;

  SelectedElement(this.ref, this.name);
}

@Injectable()
class ContextService {
  final FirebaseService _firebaseService;
  final UserService _userService;
  SelectedElement selectedCompany;
  SelectedElement selectedCompanyLocation;

  final _location = new StreamController<SelectedElement>.broadcast();

  Stream<SelectedElement> get onLocation => _location.stream;

  ContextService(this._firebaseService, this._userService);

  selectCompanyLocation(DocumentReference locationRef, String name,
      {DocumentReference companyRef, String companyName}) async {
    if (companyRef != null && companyName != null) {
      selectedCompany = SelectedElement(companyRef, companyName);
    }
    selectedCompanyLocation = new SelectedElement(locationRef, name);
    final blpUser = await _userService.getUser();
    _firebaseService.saveLastSelected(blpUser.uid, selectedCompany.ref, selectedCompanyLocation.ref);
    notifyLocationChangeListeners();
  }

  _resetContext() {
    selectedCompanyLocation = null;
    selectedCompany = null;
  }
  
  restoreContextForUser(String uid) async {
    _resetContext();
    final userData = await _firebaseService.loadUser(uid);
    final lastSelected = userData.get("lastSelected");
    if (lastSelected != null) {
      final companyRef = lastSelected["companyRef"];
      if (companyRef != null) {
        final companySnapshot = await companyRef.get();
        if (companySnapshot.exists) {
          selectedCompany = new SelectedElement(companyRef, companySnapshot.get("companyName"));
          final locationRef = lastSelected["locationRef"];
          if (locationRef != null) {
            final locationSnapshot = await locationRef.get();
            if (locationSnapshot.exists) {
              selectedCompanyLocation = SelectedElement(locationRef, locationSnapshot.get("locationName"));
              notifyLocationChangeListeners();
            }
          }
        }
      }
    }
  }

  void notifyLocationChangeListeners() {
    if (_location.hasListener) {
      _location.add(selectedCompanyLocation);
    }
  }
}
