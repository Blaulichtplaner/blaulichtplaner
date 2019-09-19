import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/workarea_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/shiftplan/models.dart';

@Component(
    selector: 'blp-shift',
    templateUrl: 'shift_component.html',
    directives: [materialDirectives, coreDirectives, routerDirectives, formDirectives, MaterialTooltipTargetDirective],
    pipes: [DatePipe],
    providers: const [materialProviders])
class ShiftComponent {
  @Input("day")
  ShiftDay day;
  @Input("selection")
  SelectionModel<Shift> selectedShifts;
  @Input("showStatus")
  bool showStatus = true;
  final WorkAreaResolver workAreaResolver;

  final _addShifts = new StreamController<ShiftDay>();
  final _editShifts = new StreamController<Shift>();

  ShiftComponent(this.workAreaResolver);

  @Output()
  Stream<ShiftDay> get addShifts => _addShifts.stream;

  @Output()
  Stream<Shift> get editShifts => _editShifts.stream;

  dayClicked() {
    _addShifts.add(day);
  }

  shiftClicked(Shift shift, Event event) {
    event.stopPropagation();
    if (event is MouseEvent) {
      if (event.shiftKey) {
        if (selectedShifts.isSelected(shift)) {
          selectedShifts.deselect(shift);
        } else {
          selectedShifts.select(shift);
        }
        return;
      }
    }
    _editShifts.add(shift);
  }
}
