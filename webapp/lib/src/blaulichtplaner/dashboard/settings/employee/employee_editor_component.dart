import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_manager_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/employee/employee_models.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/dashboard/settings/route_paths.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/firebase_service.dart';
import 'package:blaulichtplaner/src/blaulichtplaner/services.dart';

@Component(
    selector: "blp-employee-editor",
    templateUrl: "employee_editor_component.html",
    directives: [coreDirectives, formDirectives, materialDirectives, routerDirectives],
    providers: [ClassProvider(EmployeeManagerService)])
class EmployeeEditorComponent extends EditorService {
  final FirebaseService _firebaseService;

  SelectionOptions<String> titleOptions =
      SelectionOptions.fromList(["Dr.", "Dr. med.", "Prof. Dr. med.", "Dr. med. habil."]);
  SelectionOptions<String> areaOfExpertiseOptions = SelectionOptions.fromList(["Fachgebiet 1", "Fachgebiet 2"]);
  SelectionOptions<String> originOptions = SelectionOptions.fromList(["Krankenhaus", "Praxis"]);
  SelectionOptions<String> qualificationOptions = SelectionOptions.fromList(<String>["Quali 1", "Quali 2"]);

  var employee = new EmployeeModel.empty();
  String employeePath;
  String _companyId;
  String _employeeId;

  EmployeeEditorComponent(Router router, this._firebaseService) : super(router);

  @override
  save() async {
    loading = true;

    final data = employee.toMap();
    if (isValidEmployId()) {
      await _firebaseService.firestore.doc("employees/$_employeeId").update(data: data);
    } else {
      data["companyRefs"] = [_firebaseService.companyReference(_companyId)];
      await _firebaseService.firestore.collection("employees").add(data);
    }
    loading = false;
    router.navigate(settingsEmployeeManager.toUrl(parameters: {"companyId": _companyId}));
  }

  @override
  delete() async {}

  @override
  cancel() {
    router.navigate(settingsEmployeeManager.toUrl(parameters: {"companyId": _companyId}));
  }

  @override
  void onActivate(RouterState previous, RouterState current) async {
    await super.onActivate(previous, current);
    _companyId = current.parameters["companyId"];
    _employeeId = current.parameters["employeeId"];
    if (isValidEmployId()) {
      loading = true;
      final snapshot = await _firebaseService.firestore.doc("employees/$_employeeId").get();
      print(snapshot);
      employee.updateWithSnapshot(snapshot);
      loading = false;
    }
  }

  bool isValidEmployId() => _employeeId != "new";

  String stringRenderer(String option) => option;

  String get qualificationsLabel {
    final size = employee.qualifications.length;
    if (size == 0) {
      return 'Bitte Qualifikation auswählen';
    } else {
      return employee.qualifications.join(", ");
    }
  }
}
