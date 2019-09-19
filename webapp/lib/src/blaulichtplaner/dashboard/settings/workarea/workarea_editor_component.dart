import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/model/ui/has_factory.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/api/api_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workarea_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/routes.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/workarea/workarea_editor_component.template.dart'
    as uiTemplate;
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/domain/utils.dart';

import '../route_paths.dart';

class WorkAreaModel {
  String workAreaName;
  SelectionModel<Color> color = SelectionModel.single();

  WorkAreaModel.empty();

  WorkAreaModel.fromWorkArea(LocationWorkArea workArea) {
    this.workAreaName = workArea.workAreaName;
    this.color = SelectionModel.single(selected: Color("", workArea.color));
  }

  bool get hasColor =>
      color.isNotEmpty && color.selectedValues.first.cssClass != null && color.selectedValues.first.cssClass.isNotEmpty;

  LocationWorkArea toWorkArea() {
    final workArea = LocationWorkArea.empty();
    workArea.workAreaName = workAreaName;
    workArea.color = color.selectedValues.first.cssClass;
    return workArea;
  }
}

class Color implements HasUIDisplayName {
  final String label;
  final String cssClass;

  Color(this.label, this.cssClass);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Color && runtimeType == other.runtimeType && cssClass == other.cssClass;

  @override
  int get hashCode => cssClass.hashCode;

  @override
  String get uiDisplayName => label;
}

@Component(selector: 'blp-color-item-renderer', template: r'''
        <div class="color-box"><div class="color-{{cssClass}}"></div>{{displayName}}</div>
    ''', styles: [
  '.color-box div { width:16px; height:16px; margin:8px}'
      '.color-box {display: flex} ',
])
class ColorLabelRendererComponent implements RendersValue<Color> {
  String cssClass;
  String displayName;

  @override
  set value(Color newValue) {
    displayName = newValue.uiDisplayName;
    cssClass = newValue.cssClass;
  }
}

@Component(
    selector: "blp-workarea-editor",
    templateUrl: "workarea_editor_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives, routerDirectives],
    providers: [const ClassProvider(FirebaseService)])
class CompanyLocationWorkAreaEditorComponent implements OnActivate, CanReuse {
  final ApiService _apiService;
  final Router _router;
  final Routes routes;
  final WorkAreaService _workAreaService;
  final FirebaseService _firebaseService;

  final colors = {
    "vanilla-green": "Grün",
    "vanilla-blue": "Blau",
    "amber": "Amber",
    "light-green": "Hellgrün",
    "vanilla-red": "Rot",
    "blue-grey": "Blaugrau"
  };

  SelectionOptions<Color> workAreaColors = SelectionOptions.fromList([
    Color("Grün", "vanilla-green"),
    Color("Blau", "vanilla-blue"),
    Color("Amber", "amber"),
    Color("Hellgrün", "light-green"),
    Color("Rot", "vanilla-red"),
    Color("Blaugrau", "blue-grey")
  ]);

  FactoryRenderer get colorItemRenderer => (_) => uiTemplate.ColorLabelRendererComponentNgFactory;

  WorkAreaModel workArea = WorkAreaModel.empty();
  var loading = false;
  String companyId;
  DocumentReference locationRef;
  String workAreaPath;
  @ViewChild('submitButton')
  MaterialButtonComponent submitButton;
  RouterState _previous;

  CompanyLocationWorkAreaEditorComponent(
      this._apiService, this._router, this.routes, this._firebaseService, this._workAreaService);

  String get selectionWorkAreaColor =>
      workArea.hasColor ? "Farbe: " + colors[workArea.color.selectedValues.first.cssClass] : "Bitte Farbe auswählen";

  renderWorkAreaColor(Color selectOption) => selectOption.uiDisplayName;

  save() async {
    submitButton.disabled = true;
    loading = true;
    if (workAreaPath == null) {
      await _apiService.postWorkArea(locationRef.path, workArea.toWorkArea());
      await _router.navigate(
          settingsCompanyLocationDetails.toUrl(parameters: {"locationId": locationRef.id, "companyId": companyId}));
    } else {
      await _apiService.putWorkArea(locationRef.path, workAreaPath, workArea.toWorkArea());
      _router.navigate(_previous.toUrl());
    }
  }

  delete() async {
    submitButton.disabled = true;
    loading = true;
    await _apiService.deleteWorkArea(workAreaPath);
    _router.navigate(_previous.toUrl());
  }

  cancel() {
    _router.navigate(_previous.toUrl());
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    this._previous = previous;
    submitButton.disabled = false;
    loading = false;
    companyId = current.parameters["companyId"];
    final locationId = current.parameters["locationId"];
    locationRef = _firebaseService.locationReference(companyId, locationId);
    final workAreaId = current.parameters["workAreaId"];
    if (!isEmptyId(workAreaId)) {
      final transportResult = await _workAreaService.getWorkArea(locationRef, workAreaId);
      workAreaPath = transportResult.selfPath;
      workArea = WorkAreaModel.fromWorkArea(transportResult.data);
    }
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
