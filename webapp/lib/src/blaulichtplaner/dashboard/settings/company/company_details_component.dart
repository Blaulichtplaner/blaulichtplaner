import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/company_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/location_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

import '../route_paths.dart';

@Component(
    selector: 'blp-company-details',
    templateUrl: 'company_details_component.html',
    directives: [materialDirectives, coreDirectives],
    providers: [const ClassProvider(CompanyService), const ClassProvider(LocationService)])
class CompanyDetailsComponent implements OnActivate, CanReuse {
  final CompanyService _companyService;
  final LocationService _locationService;
  final ContextService contextService;
  final Router _router;

  var company = new Company.empty();
  var companyLocations = new LoadingData<TransportResult<CompanyLocation>>();

  CompanyDetailsComponent(this._companyService, this._router, this._locationService, this.contextService);

  editCompany() {
    _router.navigate(settingsCompanyEditor.toUrl(parameters: {"companyId": company.id}));
  }

  addNewLocation() {
    _router.navigate(settingsCompanyLocationEditor.toUrl(parameters: {"companyId": company.id}));
  }

  selectLocation(TransportResult<CompanyLocation> transportResult) {
    _router.navigate(
        settingsCompanyLocationDetails.toUrl(parameters: {"companyId": company.id, "locationId": transportResult.id}));
  }

  manageEmployees() {
    _router.navigate(settingsEmployeeManager.toUrl(parameters: {"companyId": company.id}));
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    company = new Company.empty();
    final companyId = current.parameters["companyId"];
    if (!isEmptyId(companyId)) {
      company = await _companyService.getCompany(companyId);
      companyLocations.init(_locationService.getLocationsForCompany(companyId));
    } else {
      // TODO show error if company id is missing
    }
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
