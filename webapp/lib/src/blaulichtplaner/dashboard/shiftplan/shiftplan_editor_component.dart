import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_datepicker/range.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:firebase/firestore.dart';
import 'package:intl/intl.dart';
import 'package:quiver/time.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';

class ShiftplanModel {
  DocumentReference selfRef;
  String label;
  SelectionModel<String> status = SelectionModel.single(selected: Shiftplan.defaultStatusOption());
  DatepickerComparison _range = new DatepickerComparison.noComparison(thisMonth(new Clock()));

  DatepickerComparison get range => _range;

  set range(DatepickerComparison value) {
    _range = value;
    label = _range.range.start.format(new DateFormat("MMMM yyyy", "de"));
  }
}

@Component(selector: 'blp-shiftplan-editor', templateUrl: 'shiftplan_editor_component.html', directives: [
  materialDirectives,
  formDirectives,
  coreDirectives,
], providers: [])
class ShiftplanEditorComponent {
  @Input("shiftplan")
  ShiftplanModel shiftplan = ShiftplanModel();
  
  String get shiftplanStatusLabel => shiftplan.status.selectedValues.length > 0
      ? itemRenderer(shiftplan.status.selectedValues.first)
      : 'Dienstplan auswählen';

  SelectionOptions<String> statusOptions = SelectionOptions.fromList(Shiftplan.statusOptions);

  final _save = new StreamController<ShiftplanModel>();
  final _cancel = new StreamController<void>();

  @Output()
  Stream<ShiftplanModel> get onSave => _save.stream;

  @Output()
  Stream<void> get onCancel => _cancel.stream;

  void saveShiftplan() {
    _save.add(shiftplan);
  }

  void cancel() {
    _cancel.add(null);
  }

  String itemRenderer(Object obj) {
    return Shiftplan.statusLabels[Shiftplan.statusOptions.indexOf(obj)];
  }
  
}
