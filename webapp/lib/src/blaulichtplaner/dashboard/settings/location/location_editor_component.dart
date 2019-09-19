import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/api/api_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/location_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/routes.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

import '../route_paths.dart';

@Component(
    selector: "blp-location-editor",
    templateUrl: "location_editor_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives, routerDirectives],
    providers:  [const ClassProvider(LocationService), const ClassProvider(FirebaseService)])
class CompanyLocationEditorComponent implements OnActivate, CanReuse {
  final ApiService _apiService;
  final Router _router;
  final Routes routes;
  final LocationService _locationService;
  final FirebaseService _firebaseService;

  var location = new CompanyLocation.empty();
  var loading = false;
  DocumentReference companyRef;
  String locationPath;
  @ViewChild('submitButton')
  MaterialButtonComponent submitButton;
  RouterState _previous;

  CompanyLocationEditorComponent(
      this._apiService, this._router, this.routes, this._locationService, this._firebaseService);

  save() async {
    submitButton.disabled = true;
    loading = true;
    if (locationPath == null) {
      final refId = await _apiService.postLocation(companyRef.path, location);
      await _router
          .navigate(settingsCompanyLocationDetails.toUrl(parameters: {"locationId": refId, "companyId": companyRef.id}));
    } else {
      await _apiService.putLocation(companyRef.path, locationPath, location);
      _router.navigate(_previous.toUrl());
    }
  }

  delete() async {
    submitButton.disabled = true;
    loading = true;
    await _apiService.deleteLocation(locationPath);
    await _router
        .navigate(settingsCompanyDetails.toUrl(parameters: {"companyId": companyRef.id}));
  }

  cancel() {
    _router.navigate(_previous.toUrl());
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    this._previous = previous;
    submitButton.disabled = false;
    loading = false;
    final companyId = current.parameters["companyId"];
    companyRef = _firebaseService.companyReference(companyId);
    final locationId = current.parameters["locationId"];
    if (!isEmptyId(locationId)) {
      final transportResult = await _locationService.getLocation(companyRef, locationId);
      locationPath = transportResult.selfPath;
      location = transportResult.data;
    }
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
