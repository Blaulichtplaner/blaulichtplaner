import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';

class FilterConfig {
  // Datum von bis
  // Unbesetzte, Abgelehnte, Beworbene
  // Location

  FilterOption option = FilterOption.withoutVote;
  DateTime selectedDate = null;
}

enum FilterOption { withoutVote, accepted, rejected }

@Component(
    selector: "blp-filter-options",
    templateUrl: "filter_options_component.html",
    directives: [materialDirectives, coreDirectives, formDirectives])
class FilterOptionsComponent {
  @Input()
  FilterConfig filterConfig;

  final _filterConfigChange = new StreamController<FilterConfig>();

  @Output()
  Stream<FilterConfig> get filterConfigChange => _filterConfigChange.stream;

  SelectionModel<FilterOption> selectedFilterOption = SelectionModel.single(selected: FilterOption.withoutVote);
  SelectionOptions<FilterOption> filterOptions = SelectionOptions.fromList(FilterOption.values);

  String get filterOptionLabel {
    if (selectedFilterOption.selectedValues.length > 0) {
      return filterOptionRenderer(selectedFilterOption.selectedValues.first);
    }
    return "Unbekannte Option";
  }
  
  String filterOptionRenderer(FilterOption option) {
    switch (option) {
      case FilterOption.accepted : return "Akzeptierte Dienste";
      case FilterOption.rejected : return "Abgelehnte Dienste";
      case FilterOption.withoutVote : return "Unbesetzte Dienste";
    }
    return "Unbekannte Option";
  }

  void selectionChanged() {
    filterConfig.option = selectedFilterOption.selectedValues.first;
    _filterConfigChange.add(filterConfig);
  }
}
