import 'package:angular_router/angular_router.dart';

import '../route_paths.dart';

final settingsOverview = new RoutePath(path: 'overview', parent: settings);
final settingsCompanyDetails = new RoutePath(path: 'companyDetails/:companyId', parent: settings);
final settingsCompanyEditor = new RoutePath(path: 'companyEditor/:companyId', parent: settings);
final settingsCompanyLocationEditor =
    new RoutePath(path: 'companyLocation/:companyId/editor/:locationId', parent: settings);
final settingsCompanyLocationDetails =
    new RoutePath(path: 'companyLocation/:companyId/details/:locationId', parent: settings);
final settingsCompanyLocationWorkAreaEditor =
    new RoutePath(path: 'locationWorkArea/:companyId/:locationId/editor/:workAreaId', parent: settings);
final settingsWorkingHoursEditor = new RoutePath(path: 'workingHours/:companyId/:locationId', parent: settings);
final settingsLocationEmployeesInvitation =
    new RoutePath(path: 'locationEmployeesInvitation/:companyId/:locationId/:employeeId', parent: settings);
final settingsEmployeeManager =
    new RoutePath(path: 'employeeManager/:companyId', parent: settings);
final settingsEmployeeEditor =
    new RoutePath(path: 'employeeEditor/:companyId/:employeeId', parent: settings);
