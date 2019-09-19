import 'dart:async';

import 'package:angular/angular.dart';
import 'package:blaulichtplaner/src/authentication/authentication.dart';
import 'package:blaulichtplaner/src/authentication/authentication_models.dart';
import 'package:blaulichtplaner/src/domain/firestore_aware_models.dart';
import 'package:blaulichtplaner/src/domain/models.dart';
import 'package:firebase/firebase.dart' as fb;

@Injectable()
class CompanyService {
  final UserService _userService;
  final firestore = fb.firestore();

  CompanyService(this._userService);

  Future<List<TransportResult<Role>>> getUserCompanies() async {
    final user = await _userService.getUser();
    List<Role> companyRoles = user.rolesForType("company");
    return companyRoles.map((role) => TransportResult(role.reference, role)).toList();
  }

  getCompany(String id) async {
    final snapshot = await firestore.doc("/companies/${id}").get();
    return new Company.fromMap(snapshot.ref.path, id, snapshot.data());
  }
}
