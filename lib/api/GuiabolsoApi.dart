import 'package:guiabolso_plugin_sodexo/model/SodexoTransaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'dart:io' show Platform;

class GuiabolsoApi {
  String email;
  String password;
  SharedPreferences localDatabase;

  static const Map<String, String> HEADERS = {
    "Origin": "Android",
    "Host": "www.guiabolso.com.br",
    "Connection": "close",
    "Content-Type": "application/json; charset=UTF-8",
    "Accept-Encoding": "gzip, deflate",
  };

  static const String EVENTS_URL = "https://www.guiabolso.com.br/API/events/";

  static const String OTHER_EVENTS_URL = EVENTS_URL + "others/";

  static const String MANUAL_TRANSACTION_URL = "https://www.guiabolso.com.br/API/v4/transactions/manual";

  static const String LOGIN_EVENT_NAME = "users:login";

  static const String UPDATE_SESSION_TOKEN_EVENT_NAME = "update:session:token";

  static const String RAWDATA_INFO_EVENT_NAME = "rawData:info";

  static const String SESSION_TOKEN_KEY = "gb_session_token";

  static const String TOKEN_KEY = "gb_token";

  static const String SODEXO_ALIMENTACAO_STATEMENT_KEY = "sodexo_alimentacao";

  static const String SODEXO_COMBUSTIVEL_STATEMENT_KEY = "sodexo_combustivel";

  static const String SODEXO_REFEICAO_STATEMENT_KEY = "sodexo_refeicao";

  static const String ACCOUNT_NAME_ALIMENTACAO = "Sodexo Alimentação";

  static const String ACCOUNT_NAME_COMBUSTIVEL = "Sodexo Combustível";

  static const String ACCOUNT_NAME_REFEICAO = "Sodexo Refeição";

  static const Map<String, String> ACCOUNT_TO_DATABASE = {
    ACCOUNT_NAME_ALIMENTACAO: SODEXO_ALIMENTACAO_STATEMENT_KEY,
    ACCOUNT_NAME_COMBUSTIVEL: SODEXO_COMBUSTIVEL_STATEMENT_KEY,
    ACCOUNT_NAME_REFEICAO: SODEXO_REFEICAO_STATEMENT_KEY,
  };

  GuiabolsoApi({this.password, this.email, this.localDatabase});

  Future<void > addExpense(SodexoTransaction sodexoTransaction, int statementId) async {
    String sessionToken = localDatabase.getString(SESSION_TOKEN_KEY);
    print("===== Guia Bolso session token $sessionToken ======");

    Map<String, String> specialContentTypeHeader = new Map.from(HEADERS);
    specialContentTypeHeader["Content-Type"] = "application/x-www-form-urlencoded";

    DateFormat dateFormatter = new DateFormat("dd/MM/yyyy");

    String date = sodexoTransaction.date;
    double value = sodexoTransaction.indicatorTransaction == "+" ? sodexoTransaction.balance.toDouble() : sodexoTransaction.balance.toDouble() * -1;
    String label = sodexoTransaction.description.trim();
    String description = "";
    String formattedDate = dateFormatter.format(DateTime.parse(date));
    String deviceToken = "noIdeaHowToGenerateThis";

    String body = "sessionToken=" + sessionToken;
    body += "&deviceToken=" + deviceToken;
    body +=" &value=" + value.toStringAsFixed(2);
    body += "&label=" + label;
    body += "&date=" + Uri.encodeQueryComponent(formattedDate);
    body += "&statementId=" + statementId.toString();
    body += "&description=" + description ;
    body += "&appToken=6.3.0.0&userPlatform=GuiaBolso&currency=BRL&categoryId=1";

    print("===== Guia Bolso add expense body $body ======");

    await http.post(MANUAL_TRANSACTION_URL, headers: specialContentTypeHeader, body: body).then((addExpenseResponse) {
      print("===== Guia Bolso add expense was a success ======");
      Map<String, dynamic> decodedReponseBody = json.decode(addExpenseResponse.body);

      int returnCode = decodedReponseBody["returnCode"];
      if (returnCode != 1) {
        print("===== Guia Bolso add expense error code ${addExpenseResponse.statusCode} ======");
        throw new Exception(addExpenseResponse.body);
      }
    }).catchError((error) async {
      print("===== Guia Bolso add expense failed with error: ======");
      print(error);

      print("===== Will now try to refresh token: ======");
      await refreshToken();

      throw error;
    });
  }

  Future<void> populateDatabaseWithStatements() async {
    Set<String> statementKeys = new Set.from([SODEXO_ALIMENTACAO_STATEMENT_KEY, SODEXO_COMBUSTIVEL_STATEMENT_KEY, SODEXO_REFEICAO_STATEMENT_KEY]);
    Set<String> statementNames = new Set.from([ACCOUNT_NAME_ALIMENTACAO, ACCOUNT_NAME_COMBUSTIVEL, ACCOUNT_NAME_REFEICAO]);

    http.Response userInfo = await fetchUserInfo();
    for (String statementKey in statementKeys) {
      if (!localDatabase.getKeys().contains(statementKey)) {
        print("===== Guia Bolso statement key $statementKey not present ======");
        if (!isRequestSuccessful(userInfo.statusCode)) {
          print("===== Guia Bolso could not fetch user info REQUEST FAILED ======");
          await refreshToken();
          throw new Exception(userInfo);
        }

        Map<String, dynamic> userInfoBodyParsed = json.decode(userInfo.body);
        String name = userInfoBodyParsed["name"];

        if (name != eventNameResponse(RAWDATA_INFO_EVENT_NAME)) {
          print("===== Guia Bolso could not fetch user info RESPONSE ERROR ======");
          await refreshToken();
          throw new Exception(userInfo);
        }

        List<dynamic> accounts = userInfoBodyParsed["payload"]["accounts"];
        for (dynamic account in accounts) {
          if (account["accountType"] == 1) {
            print("===== Guia Bolso custom account found ======");
            List<dynamic> statements = account["statements"];
            for (dynamic statement in statements) {
              String statementName = statement["name"];
              statementName = utf8.decode(statementName.codeUnits);
              print("===== Guia Bolso statement name $statementName ======");
              if (statementNames.contains(statementName)) {
                localDatabase.setInt(ACCOUNT_TO_DATABASE[statementName], statement["id"]);
              }
            }
          }
        }
      }
    }
  }

  Future<http.Response> fetchUserInfo() async {
    String token = localDatabase.getString(TOKEN_KEY);

    Map<String, String> auth = {
      "sessionToken": "",
      "token": "Bearer $token",
    };

    Map<String, dynamic> bodyObject = {
      "name": RAWDATA_INFO_EVENT_NAME,
      "auth": auth,
      "version": 6,
      "flowId": "",
      "id": "",
      "identity": {
        "xForwardedFor": "127.0.0.1"
      },
      "metadata": {},
      "payload": {
        "appToken": "6.3.0.0",
        "os": "Android",
        "userPlatform": "GuiaBolso"
      },
    };

    String body = json.encode(bodyObject);
    return http.post(EVENTS_URL, headers: HEADERS, body: body);
  }

  // Name must be url encoded
  void createStatement(String name) {
    throw new UnimplementedError();
  }

  Future<void> refreshToken() async {
    String sessionToken = localDatabase.getString(SESSION_TOKEN_KEY);
    String deviceId = await getDeviceId();

    Map<String, String> payload = {
      "appToken": "6.3.0.0",
      "deviceToken": deviceId,
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
    http.post(OTHER_EVENTS_URL, headers: HEADERS, body: body).then((loginResponse) {
      print("===== Guia Bolso token renew was a success ======");
      print(loginResponse.request.url);
      print(loginResponse.request.headers);
      print(body);
      print(loginResponse.statusCode);
      print(loginResponse.body);
      Map<String, dynamic> decodedReponseBody = json.decode(loginResponse.body);

      String name = decodedReponseBody["name"];
      if (name != eventNameResponse(UPDATE_SESSION_TOKEN_EVENT_NAME)) {
        throw new Exception(loginResponse);
      }

      String newSessionToken = decodedReponseBody["auth"]["sessionToken"];
      String newToken = decodedReponseBody["auth"]["token"];

      localDatabase.setString(SESSION_TOKEN_KEY, newSessionToken);
      localDatabase.setString(TOKEN_KEY, newToken);
    }).catchError((error) {
      print("===== Guia Bolso token renew failed with error: ======");
      print(error);

      print("===== Will now try to relogin: ======");
      login();
    });
  }

  void login() async {
    String deviceName = await getDeviceName();
    String deviceId = await getDeviceId();
    DateTime date = DateTime.now();
    String loginIdValue = date.toIso8601String() + deviceId;
    String loginId = sha1.convert(loginIdValue.codeUnits).toString();

    Map<String, String> payload = {
      "appKey": "",
      "appToken": "6.3.0.0",
      "channelId": "",
      "deviceName": deviceName,
      "deviceToken": deviceId,
      "pnToken": "",
      "mobileUserId": "",
      "origin": "Android",
      "os": "Android",
      "pwd": password,
      "userPlatform": "GuiaBolso",
      "email": email
    };

    Map<String, dynamic> bodyObject = {
      "name": LOGIN_EVENT_NAME,
      "payload": payload,
      "id": loginId,
      "version": 3,
      "flowId": "",
      "identity": {
        "xForwardedFor": "127.0.0.1"
      },
      "metadata": {},
      "auth": {},
    };

    String body = json.encode(bodyObject);
    http.post(OTHER_EVENTS_URL, headers: HEADERS, body: body).then((loginResponse) {
      print("===== Guia Bolso login was a success ======");
      print(loginResponse.body);
      Map<String, dynamic> decodedReponseBody = json.decode(loginResponse.body);

      String name = decodedReponseBody["name"];
      if (name != eventNameResponse(LOGIN_EVENT_NAME)) {
        print("===== Guia Bolso login failed with error: ======");
        print(loginResponse.toString());
      }

      String sessionToken = decodedReponseBody["auth"]["sessionToken"];
      String token = decodedReponseBody["auth"]["token"];

      localDatabase.setString(SESSION_TOKEN_KEY, sessionToken);
      localDatabase.setString(TOKEN_KEY, token);
    }).catchError((error) {
      print("===== Guia Bolso login failed with error: ======");
      print(error.toString());
    });
  }

  String eventNameResponse(String eventName) {
    return eventName + ":response";
  }

  //TODO move this method to a parent class(make one first)
  bool isRequestSuccessful(int statusCode) {
    return (statusCode ~/ 100) == 2;
  }

  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
      return androidDeviceInfo.androidId;
    } else {
      IosDeviceInfo iosDeviceInfo = await deviceInfoPlugin.iosInfo;
      return iosDeviceInfo.identifierForVendor;
    }
  }

  Future<String> getDeviceName() async {
    DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
      return androidDeviceInfo.model;
    } else {
      IosDeviceInfo iosDeviceInfo = await deviceInfoPlugin.iosInfo;
      return iosDeviceInfo.utsname.machine;
    }
  }
}