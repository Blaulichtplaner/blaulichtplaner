import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/model/ui/display_name.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:firebase/firestore.dart';

class Location implements HasUIDisplayName {
  String companyLabel;
  String locationLabel;
  DocumentReference companyRef;
  DocumentReference locationRef;

  Location(this.companyLabel, this.locationLabel, this.companyRef, this.locationRef);

  @override
  String get uiDisplayName => companyLabel + " > " + locationLabel;
}

@Injectable()
class LocationAccessService {
  final UserService _userService;

  LocationAccessService(this._userService);

  Future<List<Location>> getUserLocations() async {
    final List<Location> locations = [];
    final user = await _userService.getUser();
    List<Role> companyRoles = user.rolesForType("company");

    for (final companyRole in companyRoles) {
      final locationSnapshots = await companyRole.reference.collection("locations").get();
      for (final doc in locationSnapshots.docs) {
        final locationRef = doc.ref;
        String locationLabel = doc.get("locationName");
        locations.add(Location(companyRole.label, locationLabel, companyRole.reference, locationRef));
      }
    }
    return locations;
  }
}
