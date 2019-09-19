import 'dart:async';

import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';

export 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';

abstract class CompanyAware {
  StreamSubscription<SelectedElement> _locationSubscription;

  void initWithCompanyAndLocation();

  void cancelListener() {
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
      _locationSubscription = null;
    }
  }

  void initCompanyListener(ContextService contextService) {
    if (_locationSubscription == null) {
      _locationSubscription = contextService.onLocation.listen((selectedLocation) {
        initWithCompanyAndLocation();
      });
    }
  }
}
