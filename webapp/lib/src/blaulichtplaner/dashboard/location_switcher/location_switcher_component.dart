import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/companies/location_access_service.dart';

@Component(
    selector: 'blp-location-switcher',
    templateUrl: 'location_switcher_component.html',
    directives: [coreDirectives, MaterialDropdownSelectComponent])
class LocationSwitcherComponent implements OnInit, OnDestroy {
  final LocationAccessService _locationAccessService;
  final ContextService _contextService;
  final SelectionModel<Location> selectedLocation = SelectionModel.single();
  SelectionOptions possibleLocations = SelectionOptions.fromList([]);
  StreamSubscription _locationSubscription;

  LocationSwitcherComponent(this._locationAccessService, this._contextService);

  String get selectedLocationLabel => selectedLocation.selectedValues.length > 0
      ? renderLocation(selectedLocation.selectedValues.first)
      : 'Standort auswählen';

  String renderLocation(Location option) => option.uiDisplayName;

  @override
  Future ngOnInit() async {
    final locations = await _locationAccessService.getUserLocations();
    print(locations);
    possibleLocations = SelectionOptions.fromList(locations);
    if (_contextService.selectedCompanyLocation != null) {
      final selectedCompanyLocation = _contextService.selectedCompanyLocation;
      for (final location in locations) {
        if (selectedCompanyLocation.ref.path == location.locationRef.path) {
          selectedLocation.select(location);
        }
      }
    }
    selectedLocation.deliverSelectionChanges();
    _locationSubscription = selectedLocation.selectionChanges.listen((List<SelectionChangeRecord<Location>> data) {
      if (data.first.added.isNotEmpty) {
        final selectedOption = data.first.added.first;
        final locationRef = selectedOption.locationRef;
        final companyRef = selectedOption.companyRef;
        _contextService.selectCompanyLocation(locationRef, selectedOption.locationLabel,
            companyRef: companyRef, companyName: selectedOption.companyLabel);
      }
    });
  }

  @override
  void ngOnDestroy() {
    _locationSubscription?.cancel();
  }
}
