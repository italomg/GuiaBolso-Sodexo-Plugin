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

  static const String UPDATE_SESSION_TOKEN_EVENT_NAME = "update:session:token";

  static const String SESSION_TOKEN_KEY = "gb_session_token";

  static const String TOKEN_KEY = "gb_token";

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
    String sessionToken = localDatabase.getString(SESSION_TOKEN_KEY);

    Map<String, String> payload = {
      "appToken": "6.3.0.0",
      "deviceToken": "noIdeaHowToGenerateThis", //TODO findout this information shouldn't be hard
      "sessionToken": sessionToken,
      "userAgent": "",
    };

    Map<String, dynamic> bodyObject = {
      "name": UPDATE_SESSION_TOKEN_EVENT_NAME,
      "payload": payload,
      "version": 1,
      "auth": {},
      "flowId": "",
      "id": "",
      "identity": {
        "xForwardedFor": "127.0.0.1"
      },
      "metadata": {},
    };

    String body = json.encode(bodyObject);
    http.post(OTHER_EVENTS, headers: HEADERS, body: body).then((loginResponse) {
      print("===== Guia Bolso token renew was a success ======");
      Map<String, dynamic> decodedReponseBody = json.decode(loginResponse.body);

      String name = decodedReponseBody["name"];
      if (name != eventNameResponse(LOGIN_EVENT_NAME)) {
        print("===== Guia Bolso token renew failed with error: ======");
        print(loginResponse);
      }

      String newSessionToken = decodedReponseBody["auth"]["sessionToken"];
      String newToken = decodedReponseBody["auth"]["token"];

      localDatabase.setString(SESSION_TOKEN_KEY, newSessionToken);
      localDatabase.setString(TOKEN_KEY, newToken);
    }).catchError((error) {
      print("===== Guia Bolso token renew failed with error: ======");
      print(error);
    });
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
      "name": LOGIN_EVENT_NAME,
      "payload": payload,
      "id": "85529a1e-bd9b-4972-879d-8a5fd050be12", //TODO calculate this using some hash with timestamp
      "version": 3,
      "flowId": "",
      "identity": {
        "xForwardedFor": "127.0.0.1"
      },
      "metadata": {},
      "auth": {},
    };

    String body = json.encode(bodyObject);
    http.post(OTHER_EVENTS, headers: HEADERS, body: body).then((loginResponse) {
      print("===== Guia Bolso login was a success ======");
      Map<String, dynamic> decodedReponseBody = json.decode(loginResponse.body);

      String name = decodedReponseBody["name"];
      if (name != eventNameResponse(LOGIN_EVENT_NAME)) {
        print("===== Guia Bolso login failed with error: ======");
        print(loginResponse);
      }

      String sessionToken = decodedReponseBody["auth"]["sessionToken"];
      String token = decodedReponseBody["auth"]["token"];

      localDatabase.setString(SESSION_TOKEN_KEY, sessionToken);
      localDatabase.setString(TOKEN_KEY, token);
    }).catchError((error) {
      print("===== Guia Bolso login failed with error: ======");
      print(error);
    });
  }

  String eventNameResponse(String eventName) {
    return eventName + ":response";
  }
}