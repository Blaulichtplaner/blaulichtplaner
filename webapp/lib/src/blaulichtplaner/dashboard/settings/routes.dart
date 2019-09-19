import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import "package:blaulichtplaner/src/authentication/authentication.dart";
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';

import 'company/company_details_component.template.dart' as companyDetailsCt;
import 'location/location_details_component.template.dart' as companyLocationDetailsCt;
import 'location/location_editor_component.template.dart' as companyLocationEditorCt;
import 'settings_overview_component.template.dart' as settingsOverviewCt;
import 'workarea/workarea_editor_component.template.dart' as companyLocationWorkAreaEditorCt;
import 'company/company_editor_component.template.dart' as companyEditorCt;
import 'workinghours/workinghours_editor_component.template.dart' as workingHoursEditorCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_manager_component.template.dart' as employeeManagerCt;
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_editor_component.template.dart' as employeeManagerEditorCt;
import 'route_paths.dart' as paths; 

@Injectable()
class Routes {
  static final _companyEditorCt = new RouteDefinition(
      routePath: paths.settingsCompanyEditor,
      component: companyEditorCt.CompanyEditorComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _companyLocationEditorCt = new RouteDefinition(
      routePath: paths.settingsCompanyLocationEditor,
      component: companyLocationEditorCt.CompanyLocationEditorComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _companyLocationWorkAreaEditorCt = new RouteDefinition(
      routePath: paths.settingsCompanyLocationWorkAreaEditor,
      component: companyLocationWorkAreaEditorCt.CompanyLocationWorkAreaEditorComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _companyLocationDetailsCt = new RouteDefinition(
      routePath: paths.settingsCompanyLocationDetails,
      component: companyLocationDetailsCt.CompanyLocationDetailsComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _companyDetailsCt = new RouteDefinition(
      routePath: paths.settingsCompanyDetails,
      component: companyDetailsCt.CompanyDetailsComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _settingsOverviewCt = new RouteDefinition(
      routePath: paths.settingsOverview,
      component: settingsOverviewCt.SettingsOverviewComponentNgFactory,
      additionalData: [UserRole.user]);
  
  static final _workingHoursEditorCt = new RouteDefinition(
      routePath: paths.settingsWorkingHoursEditor,
      component: workingHoursEditorCt.WorkingHoursEditorComponentNgFactory,
      additionalData: [UserRole.user]);
  
  static final _employeeManagerCt = new RouteDefinition(
      routePath: paths.settingsEmployeeManager,
      component: employeeManagerCt.EmployeeManagerComponentNgFactory,
      additionalData: [UserRole.user]);

  static final _employeeManagerEditorCt = new RouteDefinition(
      routePath: paths.settingsEmployeeEditor,
      component: employeeManagerEditorCt.EmployeeEditorComponentNgFactory,
      additionalData: [UserRole.user]);


  final List<RouteDefinition> all = [
    _companyEditorCt,
    _settingsOverviewCt,
    _companyLocationWorkAreaEditorCt,
    _companyDetailsCt,
    _companyLocationEditorCt,
    _companyLocationDetailsCt,
    _workingHoursEditorCt,
    _employeeManagerCt,
    _employeeManagerEditorCt
  ];
}
