import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/api/api_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/company_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/routes.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

import '../route_paths.dart';

@Component(
    selector: "blp-company-editor",
    templateUrl: "company_editor_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives, routerDirectives],
    providers: [const ClassProvider(CompanyService)])
class CompanyEditorComponent implements OnActivate, CanReuse {
  final ApiService apiService;
  final Router _router;
  final Routes routes;
  final CompanyService _companyService;
  var company = new Company.empty();
  bool loading = false;
  @ViewChild('submitButton')
  MaterialButtonComponent submitButton;
  RouterState _previous;

  CompanyEditorComponent(this.apiService, this._router, this.routes, this._companyService);

  saveCompany() async {
    submitButton.disabled = true;
    loading = true;
    if (company.id == null) {
      final refId = await apiService.postCompany(company);
      await _router.navigate(settingsCompanyDetails.toUrl(parameters: {"companyId": refId}));
    } else {
      await apiService.putCompany(company);
      _router.navigate(_previous.toUrl());
    }
  }

  delete() async {
    submitButton.disabled = true;
    loading = true;
    await apiService.deleteCompany(company);
    _router.navigate(_previous.toUrl());
  }

  cancel() {
    _router.navigate(_previous.toUrl());
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    print("onActivate CompanyEditorComponent");
    submitButton.disabled = false;
    loading = false;
    company = new Company.empty();

    this._previous = previous;
    final id = current.parameters["companyId"];
    print("requested id ${id}");
    if (!isEmptyId(id)) {
      company = await _companyService.getCompany(id);
    }
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
