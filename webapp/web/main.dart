import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/src/router/router_impl.dart';
// ignore: uri_has_not_been_generated
import 'package:blaulichtplaner/app_component.template.dart' as ng;
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/routes.dart';
import 'package:firebase/firebase.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_browser.dart';

// ignore: uri_has_not_been_generated
import 'main.template.dart' as self;

const routerProvidersHash = const [
  const ClassProvider(Routes),
  const ClassProvider(FirebaseService),
  const ClassProvider(ContextService),
  const ClassProvider(UserService),
  const ClassProvider(AuthenticationService),
  const Provider(RouterHook, useClass: AuthenticationHook),
  const Provider(LocationStrategy, useClass: HashLocationStrategy),
  const Provider(PlatformLocation, useClass: BrowserPlatformLocation),
  const Provider(Location),
  const Provider(Router, useClass: RouterImpl)];

@GenerateInjector(routerProvidersHash)
final InjectorFactory injector = self.injector$Injector;

void main() {

  findSystemLocale().then((locale) {
    initializeDateFormatting(locale, "dates/").then((_) {
      initializeApp(
          apiKey: "AIzaSyB270Ubby8tjLQjjwzyUQ-s9khDfvOEdf0",
          authDomain: "blaulichtplaner.firebaseapp.com",
          databaseURL: "https://blaulichtplaner.firebaseio.com",
          projectId: "blaulichtplaner",
          storageBucket: "blaulichtplaner.appspot.com",
          messagingSenderId: "946323987274");
      runApp(ng.AppComponentNgFactory, createInjector: injector);
    });
  });
}
