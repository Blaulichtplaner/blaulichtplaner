import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_router/angular_router.dart';

abstract class EditorService implements OnActivate, CanReuse {
  final Router router;
  RouterState previous;
  @ViewChild('submitButton')
  MaterialButtonComponent submitButton;
  var loading = false;


  EditorService(this.router);

  save();

  delete();

  cancel() {
    router.navigate(previous.toUrl());
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    this.previous = previous;
  }

  @override
  Future<bool> canReuse(RouterState current, RouterState next) async {
    return false;
  }
}
