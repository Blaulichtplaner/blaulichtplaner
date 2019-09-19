import "dart:async";

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/context_service.dart';
import 'package:blaulichtplaner/src/routes.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';

class BlpUser {
  final String uid;
  final String displayName;
  final String photoURL;
  final String email;
  final bool emailVerified;
  final bool registrationComplete;
  Map<String, List<Role>> _roles = {};

  BlpUser(this.uid, this.displayName, this.photoURL, this.email, this.emailVerified, this.registrationComplete);

  bool isLoggedIn() {
    return uid != null;
  }

  List<Role> rolesForType(String type) {
    return _roles[type];
  }
}

@Injectable()
class UserService {
  final _waitingUserRequests = <Completer<BlpUser>>[];
  bool _userIsSet = false;
  BlpUser _user;

  Future<BlpUser> getUser() async {
    if (_userIsSet) {
      return _user;
    } else {
      Completer futureUser = new Completer<BlpUser>();
      _waitingUserRequests.add(futureUser);
      return futureUser.future;
    }
  }

  _decideValue(String value, String fallback) {
    if (value != null && value.isNotEmpty) {
      return value;
    } else {
      return fallback;
    }
  }

  _createDisplayName(String firstName, String lastName) {
    if (firstName != null && lastName != null) {
      return (firstName + " " + lastName).trim();
    } else {
      return null;
    }
  }

  Future<BlpUser> updateUser(fb.User firebaseUser) async {
    if (firebaseUser == null) {
      _userIsSet = false;
      _user = BlpUser(null, null, null, null, false, false);
    } else {
      final document = await fb.firestore().collection("users").doc(firebaseUser.uid).get();
      if (document.exists) {
        final data = document.data();
        String role = data["role"];
        String firstName = data["firstName"];
        String lastName = data["lastName"];
        String photoURL = data["photoURL"];

        _user = BlpUser(
            firebaseUser.uid,
            _decideValue(_createDisplayName(firstName, lastName), firebaseUser.displayName),
            _decideValue(photoURL, firebaseUser.photoURL),
            firebaseUser.email,
            firebaseUser.emailVerified,
            true);

        print("Reading roles...");

        QuerySnapshot querySnapshot =
            await fb.firestore().collection("users").doc(firebaseUser.uid).collection("roles").get();

        for (DocumentSnapshot snapshot in querySnapshot.docs) {
          String type = snapshot.get("type");
          List<Role> typeRoles = _user._roles.putIfAbsent(type, () => List());
          typeRoles.add(Role.fromSnapshot(snapshot));
        }

        print("Done reading roles.");

        _userIsSet = true;
      } else {
        _user = BlpUser(firebaseUser.uid, firebaseUser.displayName, firebaseUser.photoURL, firebaseUser.email,
            firebaseUser.emailVerified, false);
        _userIsSet = true;
      }
    }
    if (_userIsSet) {
      _waitingUserRequests.forEach((completer) {
        completer.complete(_user);
      });
      _waitingUserRequests.clear();
    }
    return _user;
  }

  bool isUserLoggedIn() {
    return _user != null && _user.isLoggedIn();
  }
}

@Injectable()
class AuthenticationHook extends RouterHook {
  final UserService userService;

  AuthenticationHook(UserService userService) : this.userService = userService;

  @override
  Future<bool> canActivate(Object componentInstance, RouterState oldState, RouterState newState) async {
/*    print("RouterHook.canActivate Current user: ${user?.uid}, oldState:${oldState
        .toString()}, newState: ${newState.routePath
        .path}");*/
    List<UserRole> authRoles = newState.routePath.additionalData;
    if (authRoles == null) {
      //print("RouterHook.canActivate true, no roles");
      return true;
    } else {
      // TODO getUser might not return if user is not logged in. check if user is logged in first
//      final user = await userService.getUser();

      bool canActivate = true; // user.hasRoles(authRoles);
      //print("RouterHook.canActivate ${canActivate}");
      return canActivate;
    }
  }
}

@Injectable()
class AuthenticationService {
  final fb.Auth auth;
  final Router _router;
  final Routes _routes;
  final UserService _userService;
  final ContextService _contextService;

  AuthenticationService(Router router, UserService userService, this._routes, this._contextService)
      : auth = fb.auth(),
        this._router = router,
        this._userService = userService {
    _init();
  }

  _init() {
    auth.onIdTokenChanged.listen((newUser) async {
      print("onIdTokenChanged: $newUser");
      final userWasLoggedIn = _userService.isUserLoggedIn();
      BlpUser blpUser = await _userService.updateUser(newUser);
      if (!blpUser.isLoggedIn()) {
        print("user is null, show welcome screen");
        _router.navigate(_routes.welcome.path);
      } else {
        if (!blpUser.emailVerified) {
          _router.navigate(_routes.welcome.path, NavigationParams(queryParameters: {"error": "notVerified"}));
        } else if (!blpUser.registrationComplete) {
          print("registration unfinished");
          signOut();
        } else {
          if (!userWasLoggedIn) {
            print("restore user context");
            _contextService.restoreContextForUser(blpUser.uid);

            print("current route: ${_router.current}");
            if (_router.current == null || _router.current.toUrl().isEmpty) {
              print("navigate to dashboard");
              final result = await _router.navigate("/dashboard/overview");
              print("/dashboard/overview - ${result}");
            } else {
              String currentRoute = _router.current.toUrl();
              print("currentRoute [${currentRoute}]");
            }
          }
        }
      }
    });
  }

  signInWithGoogle() async {
    var provider = new fb.GoogleAuthProvider();
    try {
      await auth.signInWithPopup(provider);
      _router.navigate("/dashboard/overview");
    } catch (e) {
      print("Error in sign in with Google: $e");
    }
  }

  registerWithGoogle() async {
    final provider = new fb.GoogleAuthProvider();
    try {
      final userCredential = await auth.signInWithPopup(provider);
      final displayName = userCredential.user.displayName ?? "";
      final email = userCredential.user.email ?? "";
      _router.navigate(_routes.registration.path,
          new NavigationParams(queryParameters: {"displayName": displayName, "email": email}));
    } catch (e) {
      print("Error in sign in with Google: $e");
    }
  }

  Future<fb.UserCredential> registerWithEmail(String email, String password) {
    return auth.createUserWithEmailAndPassword(email, password);
  }

  login(String email, String password) {
    return auth.signInWithEmailAndPassword(email, password);
  }

  signOut() async {
    await auth.signOut();
  }
}
