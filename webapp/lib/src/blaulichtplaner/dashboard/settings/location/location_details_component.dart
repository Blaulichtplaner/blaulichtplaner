import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/company_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/location_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workarea_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

import '../route_paths.dart';

@Component(selector: 'blp-location-details', templateUrl: 'location_details_component.html', directives: [
  materialDirectives,
  coreDirectives
], providers: [
  const ClassProvider(CompanyService),
  const ClassProvider(LocationService),
  const ClassProvider(FirebaseService)
])
class CompanyLocationDetailsComponent implements OnActivate, CanReuse {
  final CompanyService _companyService;
  final LocationService _locationService;
  final WorkAreaService _workAreaService;
  final FirebaseService _firebaseService;
  final Router _router;

  String companyId;
  String locationId;
  var company = new Company.empty();
  var location = new CompanyLocation.empty();
  var workAreas = new LoadingData<TransportResult<LocationWorkArea>>();

  CompanyLocationDetailsComponent(
      this._companyService, this._router, this._locationService, this._firebaseService, this._workAreaService);

  edit() {
    _router.navigate(settingsCompanyLocationEditor.toUrl(parameters: {"companyId": companyId, "locationId": locationId}));
  }

  showWorkingHours() {
    _router.navigate(settingsWorkingHoursEditor.toUrl(parameters: {"companyId": companyId, "locationId": locationId}));
  }

  addNewWorkArea() {
    _router.navigate(
        settingsCompanyLocationWorkAreaEditor.toUrl(parameters: {"companyId": companyId, "locationId": locationId}));
  }

  selectWorkArea(String workAreaId) {
    _router.navigate(settingsCompanyLocationWorkAreaEditor
        .toUrl(parameters: {"companyId": companyId, "locationId": locationId, "workAreaId": workAreaId}));
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    companyId = current.parameters["companyId"];
    locationId = current.parameters["locationId"];
    if (!isEmptyId(locationId) && !isEmptyId(companyId)) {
      company = await _companyService.getCompany(companyId);
      final transportResult =
          await _locationService.getLocation(_firebaseService.companyReference(companyId), locationId);
      location = transportResult.data;
      workAreas.init(_workAreaService.getWorkAreaForCompanyAndLocation(transportResult.selfRef));
    } else {
      // TODO show error if company id is missing
    }
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
