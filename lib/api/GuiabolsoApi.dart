import 'package:guiabolso_plugin_sodexo/model/SodexoTransaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuiabolsoApi {
  String email;
  String cpf;
  SharedPreferences localDatabase;

  static const Map<String, String> HEADERS = {
    "Origin": "Android",
    "Host": "www.guiabolso.com.br",
    "Connection": "close",
    "Content-Type": "application/json; charset=UTF-8",
    "Accept-Encoding": "gzip, deflate",
  };

  static const String OTHER_EVENTS = "https://www.guiabolso.com.br/API/events/others/";

  static const String LOGIN_EVENT_NAME = "users:login";

  static const String SESSION_TOKEN = "gb_session_token";

  static const String TOKEN = "gb_token";

  GuiabolsoApi({this.cpf, this.email, this.localDatabase});

  void addExpense(SodexoTransaction sodexoTransaction, int statementId) {
    // Must try to add expense, on failure try to get a fresh token if that also fail try logging in again
  }

  Map<String, int> getStatements() {
    return null;
  }

  // Name must be url encoded
  void createStatement(String name) {

  }

  void refreshToken() {

  }

  void login() {
    Map<String, String> payload = {
      "appKey": "",
      "appToken": "6.3.0.0",
      "channelId": "",
      "deviceName": "deviceNameGoesHere", //TODO findout this information shouldn't be hard
      "deviceToken": "noIdeaHowToGenerateThis", //TODO findout this information shouldn't be hard
      "pnToken": "",
      "mobileUserId": "",
      "origin": "Android",
      "os": "Android",
      "pwd": "{passwordPlaceholder}",
      "userPlatform": "GuiaBolso",
      "email": "{emailPlaceholder}"
    };

    Map<String, dynamic> bodyObject = {
      "flowId": "",
      "id": "85529a1e-bd9b-4972-879d-8a5fd050be12", //TODO calculate this using some hash with timestamp
      "name": LOGIN_EVENT_NAME,
      "version": 3,
      "identity": {
        "xForwardedFor": "127.0.0.1"
      },
      "payload": payload,
      "metadata": {},
      "auth": {},
    };

    String body = json.encode(bodyObject);
    http.post(OTHER_EVENTS, headers: HEADERS, body: body).then((loginResponse) {
      print("===== Guia Bolso login was a success ======");
      Map<String, dynamic> decodedReponseBody = json.decode(loginResponse.body);

      String name = decodedReponseBody["name"];
      if (name != eventNameResponse(LOGIN_EVENT_NAME)) {
        print("===== login failed with error: ======");
        print(loginResponse);
      }

      String sessionToken = decodedReponseBody["auth"]["sessionToken"];
      String token = decodedReponseBody["auth"]["token"];

      localDatabase.setString(SESSION_TOKEN, sessionToken);
      localDatabase.setString(TOKEN, token);
    }).catchError((error) {
      print("===== login failed with error: ======");
      print(error);
    });
  }

  String eventNameResponse(String eventName) {
    return eventName + ":response";
  }
}