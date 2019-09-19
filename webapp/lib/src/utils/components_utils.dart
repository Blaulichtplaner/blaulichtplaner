
import 'package:angular/angular.dart';
import 'package:angular_components/material_datepicker/material_date_time_picker.dart';
import 'package:angular_forms/angular_forms.dart';

const valueAccessor = const OpaqueToken('NgValueAccessor');

@Directive(
  selector: 'material-date-time-picker[dateTime]',
  providers: const [
    const ExistingProvider.forToken(ngValueAccessor, DateTimePickerValueAccessor),
  ],
)
class DateTimePickerValueAccessor implements ControlValueAccessor, OnDestroy {
  final MaterialDateTimePickerComponent _picker;

  DateTimePickerValueAccessor(this._picker) {}

  @override
  void writeValue(newValue) {
    if (newValue is DateTime) {
      _picker.dateTime = newValue;
    }
  }

  @override
  void ngOnDestroy() {}

  @override
  void onDisabledChanged(bool isDisabled) {}

  @override
  void registerOnChange(ChangeFunction f) {}

  @override
  void registerOnTouched(TouchFunction f) {}
}
