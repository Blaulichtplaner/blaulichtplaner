import 'dart:async';

import 'package:http/http.dart';
import 'package:node_http/node_http.dart';
import 'package:node_io/node_io.dart';

class MailService {
  final Client _client = NodeClient();
  final String _basicAuth;

  final String baseUrl = "https://api.mailgun.net/v3/mg.blaulichtplaner.de";

  MailService(this._basicAuth);

  Future<Response> sendInvite(String userEmail, String confirmUrl) async {
    final request = {};
    request["to"] = userEmail;
    request["from"] = "\"Blaulichtplaner App\" <as@grundid.de>";
    request["subject"] = "Einladung zum Blaulichtplaner";

    String mailMessage = await File('templates/user_invite.html').readAsString();
    String mimeMessage = mailMessage.replaceAll(RegExp("##confirmLink##"), confirmUrl);

    request["html"] = mimeMessage;

    final headers = {"Authorization": _basicAuth};

    return _client.post(baseUrl + "/messages", headers: headers, body: request);
  }
}
