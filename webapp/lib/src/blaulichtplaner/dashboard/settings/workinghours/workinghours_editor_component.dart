import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/api/api_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workinghours_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/routes.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

import '../../../../domain/models.dart';

@Component(
    selector: "blp-workinghours-editor",
    templateUrl: "workinghours_editor_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives, routerDirectives],
    providers: [ClassProvider(WorkingHoursService), const ClassProvider(FirebaseService)],
    pipes: [DatePipe])
class WorkingHoursEditorComponent implements OnActivate, CanReuse {
  final ApiService _apiService;
  final Router _router;
  final Routes routes;
  final WorkingHoursService _workingHoursService;
  final FirebaseService _firebaseService;
  WorkingHours workingHours = new WorkingHours();

  var loading = false;
  DocumentReference companyRef;
  String locationPath;
  @ViewChild('submitButton')
  MaterialButtonComponent submitButton;
  RouterState _previous;
  DocumentReference locationRef;
  var workingHoursList = new LoadingData<TransportResult<WorkingHours>>();

  WorkingHoursEditorComponent(
      this._apiService, this._router, this.routes, this._firebaseService, this._workingHoursService);

  save() async {
    //submitButton.disabled = true;
    //loading = true;
    await _workingHoursService.save(locationRef, workingHours);
    workingHours = new WorkingHours();
    workingHoursList.init(_workingHoursService.getWorkingHoursForCompany(locationRef));
  }

  deleteWorkingHours(TransportResult<WorkingHours> tr) async {
    await _workingHoursService.delete(_firebaseService.firestore.doc(tr.selfPath));
    workingHoursList.init(_workingHoursService.getWorkingHoursForCompany(locationRef));
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
    final locationId = current.parameters["locationId"];
    locationRef = _firebaseService.locationReference(companyId, locationId);
    workingHoursList.init(_workingHoursService.getWorkingHoursForCompany(locationRef));
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
