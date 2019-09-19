import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/company_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

import 'route_paths.dart' as settingsPaths;

@Component(
  selector: 'blp-settings-overview',
  templateUrl: 'settings_overview_component.html',
  directives: [materialDirectives, coreDirectives, routerDirectives],
  providers: const [materialProviders, ClassProvider(CompanyService)],
)
class SettingsOverviewComponent implements OnActivate {
  final Router _router;
  final CompanyService _companyService;
  final ContextService contextService;

  var userCompanies = new LoadingData<TransportResult<Role>>();

  SettingsOverviewComponent(this._router, this._companyService, this.contextService);

  selectCompany(TransportResult<Role> tr) async {
    await _router.navigate(settingsPaths.settingsCompanyDetails.toUrl(parameters: {"companyId": tr.id}));
  }

  addNewCompany() async {
    _router.navigate(settingsPaths.settingsCompanyEditor.toUrl());
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    userCompanies.init(_companyService.getUserCompanies());
  }
}
