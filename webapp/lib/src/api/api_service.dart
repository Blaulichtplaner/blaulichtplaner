import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/build_config.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:blaulichtplaner/src/domain/user.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart';
import 'package:http/http.dart';
import 'package:nanoid/nanoid.dart';

@Deprecated("switched to http calls, later App Calls")
abstract class AsyncRequest<T> {
  final String requestCollection;
  final DocumentReference api;
  final CollectionReference apiResult;
  final UserService _userService;

  AsyncRequest(this.requestCollection, this._userService)
      : api = fb.firestore().collection("api").doc("v1"),
        apiResult = fb.firestore().collection("apiResult");

  Map<String, Object> _convertData(T data);

  performRequest(T data) async {
    final user = await _userService.getUser();
    if (user.isLoggedIn()) {
      var dataMap = _convertData(data);
      dataMap["uid"] = user.uid;
      final requestRef = await api.collection(requestCollection).add(dataMap);
      final resultDocRef = apiResult.doc(user.uid).collection("requests").doc(requestRef.id);
      final Completer<void> completer = new Completer();
      StreamSubscription subscription = null;
      subscription = resultDocRef.onSnapshot.listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          final status = data["status"];
          if (status == "finished") {
            subscription.cancel();
            completer.complete();
          } else if (status == "failed") {
            subscription.cancel();
            completer.completeError("error");
          }
        }
      });
      return completer.future;
    } else {
      throw new Exception("User not logged in");
    }
  }
}

abstract class AsyncHttpRequest<T> {
  final UserService _userService;
  final Client _client;
  final String _requestUrl;

  AsyncHttpRequest(this._userService, this._client, this._requestUrl);

  Map<String, Object> _convertData(T data);

  Future<String> performPostRequest(String parentRef, T data) async {
    final user = await _userService.getUser();
    if (user.isLoggedIn()) {
      var dataMap = {"parentRef": parentRef, "data": _convertData(data)};
      final headers = {"Authorization": user.uid, "Content-Type": "application/json"};
      try {
        final response = await _client.post(_requestUrl, headers: headers, body: json.encode(dataMap));
        if (response.statusCode != 201) {
          throw new Exception("Error ${response.statusCode}");
        } else {
          print("location: ${json.encode(response.headers)}");
          return response.headers["location"];
        }
      } catch (e) {
        print("ERROR: ${e}");
        throw new Exception("error during Http request");
      }
    } else {
      throw new Exception("User not logged in");
    }
  }

  performPutRequest(String parentRef, String selfRef, T data) async {
    final user = await _userService.getUser();
    if (user.isLoggedIn()) {
      var dataMap = <String, dynamic>{"parentRef": parentRef};
      if (data != null) {
        dataMap["data"] = _convertData(data);
      }
      final headers = {"Authorization": user.uid, "Content-Type": "application/json"};
      final response = await _client.put(_requestUrl + "/" + Uri.encodeComponent(selfRef),
          headers: headers, body: json.encode(dataMap));
      if (response.statusCode != 200) {
        throw new Exception("Error ${response.statusCode}");
      } else {
        return true;
      }
    } else {
      throw new Exception("User not logged in");
    }
  }

  performDeleteRequest(String locationRef) async {
    final user = await _userService.getUser();
    if (user.isLoggedIn()) {
      final headers = {"Authorization": user.uid};
      final response = await _client.delete(_requestUrl + "/" + Uri.encodeComponent(locationRef), headers: headers);
      if (response.statusCode != 200) {
        throw new Exception("Error ${response.statusCode}");
      } else {
        return true;
      }
    } else {
      throw new Exception("User not logged in");
    }
  }
}

class CompanyRequest extends AsyncHttpRequest<Company> {
  CompanyRequest(UserService userService, Client client) : super(userService, client, BuildConfig.baseUrl + '/company');

  @override
  Map<String, Object> _convertData(Company data) {
    return data.toMap();
  }
}

class UserRequest extends AsyncHttpRequest<Map<String, dynamic>> {
  UserRequest(UserService userService, Client client) : super(userService, client, BuildConfig.baseUrl + "/user");

  @override
  Map<String, Object> _convertData(Map<String, dynamic> data) {
    return data;
  }
}

class LocationRequest extends AsyncHttpRequest<CompanyLocation> {
  LocationRequest(UserService userService, Client client)
      : super(userService, client, BuildConfig.baseUrl + '/location');

  @override
  Map<String, Object> _convertData(CompanyLocation data) {
    return data.toMap();
  }
}

class WorkAreaRequest extends AsyncHttpRequest<LocationWorkArea> {
  WorkAreaRequest(UserService userService, Client client)
      : super(userService, client, BuildConfig.baseUrl + '/workArea');

  @override
  Map<String, Object> _convertData(LocationWorkArea data) {
    return data.toMap();
  }
}

class InvitationRequest extends AsyncHttpRequest<Invitation> {
  InvitationRequest(UserService userService, Client client)
      : super(userService, client, BuildConfig.baseUrl + '/invitation');

  @override
  Map<String, Object> _convertData(Invitation data) {
    return data.toMap();
  }
}

@Injectable()
class ApiService {
  final UserService _userService;
  final Client _client;

  final CompanyRequest companyRequestHandler;
  final LocationRequest locationRequestHandler;
  final WorkAreaRequest workAreaRequestHandler;
  final UserRequest userRequestHandler;
  final InvitationRequest invitationRequestHandler;

  ApiService(this._userService, this._client)
      : companyRequestHandler = new CompanyRequest(_userService, _client),
        locationRequestHandler = new LocationRequest(_userService, _client),
        workAreaRequestHandler = new WorkAreaRequest(_userService, _client),
        userRequestHandler = new UserRequest(_userService, _client),
        invitationRequestHandler = new InvitationRequest(_userService, _client);

  addUser(NewUserData userData) async {
    String token = nanoid(64);
    Map<String, dynamic> data = userData.toMap();
    data["token"] = token;
    await fb.firestore().collection("registrations").doc(userData.uid).set(data);
    await userRequestHandler.performPostRequest(null, {"token": token});
  }

  Future<bool> isUserRegistered(String userId) async {
    final snapshot = await fb.firestore().collection("users").doc(userId).get();
    return (snapshot.exists && snapshot.data()["role"] != null);
  }

  postCompany(Company companyData) async {
    return companyRequestHandler.performPostRequest(null, companyData);
  }

  putCompany(Company companyData) async {
    return companyRequestHandler.performPutRequest(null, companyData.selfPath, companyData);
  }

  deleteCompany(Company companyData) async {
    return companyRequestHandler.performDeleteRequest(companyData.selfPath);
  }

  postLocation(String parentCompanyRef, CompanyLocation location) {
    return locationRequestHandler.performPostRequest(parentCompanyRef, location);
  }

  putLocation(String parentRef, String locationRef, CompanyLocation location) {
    return locationRequestHandler.performPutRequest(parentRef, locationRef, location);
  }

  deleteLocation(String selfRef) {
    return locationRequestHandler.performDeleteRequest(selfRef);
  }

  postWorkArea(String parentLocationRef, LocationWorkArea workArea) {
    return workAreaRequestHandler.performPostRequest(parentLocationRef, workArea);
  }

  putWorkArea(String parentRef, String workAreaRef, LocationWorkArea workArea) {
    return workAreaRequestHandler.performPutRequest(parentRef, workAreaRef, workArea);
  }

  deleteWorkArea(String selfRef) {
    return workAreaRequestHandler.performDeleteRequest(selfRef);
  }
  
  postInvitation(Invitation invitation) {
    return invitationRequestHandler.performPostRequest("", invitation);
  }

  putInvitation(String invitationId) async {
    return invitationRequestHandler.performPutRequest("", invitationId, null);
  }
}
