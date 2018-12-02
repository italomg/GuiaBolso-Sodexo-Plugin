import 'package:guiabolso_plugin_sodexo/model/SodexoCard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SodexoApi {

  String extractUrl = "https://mobile.sodexobeneficios.com.br/prod/balance/v2/searchBalanceAndTransactionsMobile?versaoChamada=2.0&cardsStatus=active%2CblockedButEligibleToBeShown&araras=false";
  static const String RENEW_TOKEN_URL = "https://mobile.sodexobeneficios.com.br/prod/userportal/v2/renewToken";
  static const String LOGIN_URL = "https://mobile.sodexobeneficios.com.br/prod/userportal/v2/login";

  static const String AUTHORIZATION_TOKEN_KEY = "authorization_token";
  static const String RENEW_TOKEN_KEY = "renew_token";
  static const String USER_ID_KEY = "user_id";

  String cpf;
  String password;
  SharedPreferences localDatabase;

  SodexoApi({this.cpf, this.password, this.localDatabase});

  Future<List<SodexoCard>> fetchLatestTransactions(String initialDate, int retry) async {
    if (retry >= 5) {
      return null;
    }

    String authorizationTokenValue = localDatabase.get(AUTHORIZATION_TOKEN_KEY);

    Map<String, String> headers = {
      "consumerid": "consumerSearchBalanceMobile",
      "contextid": "SearchBalanceService",
      "systemid": "7",
      "systemname": "Mobile",
      "icllocale": "pt_BR",
      "version": "2.0",
      "correlationid": "2121-21-21 21:21:2169ea835e294efb65",
      "addressip": "fef0::f01a:0ca5:fe10:beef%dummy0",
      "Authorization": authorizationTokenValue,
      "Host": "mobile.sodexobeneficios.com.br",
      "Connection": "close",
      "Accept-Encoding": "gzip, deflate",
      "User-Agent": "okhttp/3.10.0",
      "Cache-Control": "no-cache",
    };

    extractUrl = extractUrl + "&initialDate=$initialDate&document=$cpf";

    http.Response sodexoExtractResponse = await http.get(
        extractUrl, headers: headers);

    if (isRequestSuccessful(sodexoExtractResponse.statusCode)) {
      print("===== Sodexo extract fetch REQUEST was a success ======");
      return parseSodexoExtractResponse(sodexoExtractResponse);
    } else {
      print("===== Sodexo extract fetch REQUEST FAILED ======");
      await refreshToken(localDatabase);
      return await fetchLatestTransactions(initialDate, retry + 1);
    }
  }

  Future<void> refreshToken(SharedPreferences localDatabase) async {
    Map<String, String> headers = {
      "systemid": "7",
      "systemname": "Mobile",
      "icllocale": "pt_BR",
      "version": "2.0",
      "consumerid": "consumerUserMobile",
      "contextid": "UserPortalService",
      "Content-Type": "application/json; charset=utf-8",
      "Host": "mobile.sodexobeneficios.com.br",
      "Connection": "close",
      "Accept-Encoding": "gzip, deflate",
      "User-Agent": "okhttp/3.10.0",
    };

    String refreshToken = localDatabase.getString(RENEW_TOKEN_KEY);
    int userId = localDatabase.getInt(USER_ID_KEY);

    Map<String, dynamic> bodyObject = {
      "refreshToken": refreshToken,
      "userid": userId,
    };

    String body = json.encode(bodyObject);
    
    await http.post(RENEW_TOKEN_URL, body: body, headers: headers ).then((sodexoExtractResponse) async {
      if (isRequestSuccessful(sodexoExtractResponse.statusCode)) {
        print("===== Sodexo token renew REQUEST was a success ======");
        print(sodexoExtractResponse.statusCode);
        String newToken = json.decode(sodexoExtractResponse.body)["accessToken"];
        localDatabase.setString(AUTHORIZATION_TOKEN_KEY, newToken);
      } else {
        print("===== Sodexo refresh token RESPONSE ERROR.... login will be retried ======");
        await login(localDatabase);
      }
    }).catchError((error) {
      print("===== Sodexo refresh token REQUEST FAILED ======");
      print(error);

      throw error;
    });

  }

  Future<void> login(SharedPreferences localDatabase) async {
    Map<String, String> headers = {
      "consumerid": "consumerUserMobile",
      "contextid": "UserPortalService",
      "systemid": "7",
      "systemname": "Mobile",
      "icllocale": "pt_BR",
      "version": "2.0",
      "correlationid": "2018-10-30 01:53:4169ea835e294efb65",
      "addressip": "fe80::109a:6eff:fe18:6e30%dummy0",
      "Host": "mobile.sodexobeneficios.com.br",
      "Connection": "close",
      "Content-Type": "application/json; charset=UTF-8",
      "Accept-Encoding": "gzip, deflate",
      "User-Agent": "okhttp/3.10.0",
    };

    Map<String, dynamic> bodyObject = {
      "user": {
        "araras":"false",
        "cpf":cpf,
        "idMobile":"someMobileId",
        "mobileAccess":"true",
        "password":password,
        "type":"B",
        "version":1
      }
    };
    String body = json.encode(bodyObject);
    http.post(LOGIN_URL, headers: headers, body: body).then((loginResponse) {
      print("===== Sodexo login REQUEST was a success ======");
      Map<String, dynamic> decodedReponseBody = json.decode(loginResponse.body);

      if (decodedReponseBody["user"] == null) {
        throw new Exception(loginResponse.body);
      }

      int userId = decodedReponseBody["user"]["id"];
      String authorizationToken = decodedReponseBody["accessToken"];
      String renewToken = decodedReponseBody["refreshToken"];

      localDatabase.setInt(USER_ID_KEY, userId);
      localDatabase.setString(AUTHORIZATION_TOKEN_KEY, authorizationToken);
      localDatabase.setString(RENEW_TOKEN_KEY, renewToken);
    }).catchError((error) {
      print("===== Sodexo login REQUEST FAILED with error: ======");
      print(error);

      throw error;
    });
  }

  List<SodexoCard> parseSodexoExtractResponse(http.Response sodexoExtractResponse) {
    List<SodexoCard> parsedEntities = new List<SodexoCard>();
    List<dynamic> allCardsJson = json.decode(sodexoExtractResponse.body)["AccountDataReturnV2"];
    allCardsJson.forEach((cardData) {
      SodexoCard sodexoCard = SodexoCard.fromJson(cardData);
      parsedEntities.add(sodexoCard);
    });

    return parsedEntities;
  }

  //TODO move this method to a parent class(make one first)
  bool isRequestSuccessful(int statusCode) {
    return (statusCode ~/ 100) == 2;
  }

}