import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

import 'company_handler.dart';
import 'employee_handler.dart';
import 'invitation_handler.dart';
import 'location_handler.dart';
import 'user_handler.dart';
import 'workarea_handler.dart';

void main() {
  final admin = FirebaseAdmin.instance;
  final app = admin.initializeApp(AppOptions());
  
  functions['company'] = FirebaseFunctions.https.onRequest(CompanyHandler(app).handler());
  functions['location'] = FirebaseFunctions.https.onRequest(LocationHandler(app).handler());
  functions['workArea'] = FirebaseFunctions.https.onRequest(WorkAreaHandler(app).handler());
  functions['employee'] = FirebaseFunctions.https.onRequest(EmployeeHandler(app).handler());
  functions['user'] = FirebaseFunctions.https.onRequest(UserHandler(app).handler());
  functions['invitation'] = FirebaseFunctions.https.onRequest(InvitationHandler(app).handler());

  functions['test'] = FirebaseFunctions.https.onRequest((ExpressHttpRequest request) {});
}
