import 'package:guiabolso_plugin_sodexo/model/SodexoCard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Make these methods non static
class SodexoApi {

  static String extractUrl = "https://mobile.sodexobeneficios.com.br/prod/balance/v2/searchBalanceAndTransactionsMobile?versaoChamada=2.0&cardsStatus=active%2CblockedButEligibleToBeShown&araras=false";
  static final String renewTokenUrl = "https://mobile.sodexobeneficios.com.br/prod/userportal/v2/renewToken";
  static final String loginUrl = "https://mobile.sodexobeneficios.com.br/prod/userportal/v2/login";

  static final String authorizationTokenKey = "authorization_token";
  static final String renewTokenKey = "renew_token";
  static final String userIdKey = "user_id";

  static String cpf;
  static String password;
  static SharedPreferences localDatabase;

  static Future<List<SodexoCard>> fetchLatestTransactions(String cpf, String password, String initialDate, SharedPreferences localDatabase) async {
    SodexoApi.cpf = cpf;
    SodexoApi.password = password;
    SodexoApi.localDatabase = localDatabase;

    String authorizationTokenValue = localDatabase.get(authorizationTokenKey);

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
      print("===== Sodexo extract fetch was a success ======");
      return parseSodexoExtractResponse(sodexoExtractResponse);
    } else {
      print("===== Sodexo extract fetch failed ======");
      refreshToken(localDatabase);
    }

    return null;
  }

  static void refreshToken(SharedPreferences localDatabase) {
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

    String refreshToken = localDatabase.getString(renewTokenKey);
    int userId = localDatabase.getInt(userIdKey);

    Map<String, dynamic> bodyObject = {
      "refreshToken": refreshToken,
      "userid": userId,
    };

    String body = json.encode(bodyObject);
    
    http.post(renewTokenUrl, body: body, headers: headers ).then((sodexoExtractResponse) {
      if (isRequestSuccessful(sodexoExtractResponse.statusCode)) {
        print("===== token renew was a success ======");
        print(sodexoExtractResponse.statusCode);
        String newToken = json.decode(sodexoExtractResponse.body)["accessToken"];
        localDatabase.setString(authorizationTokenKey, newToken);
      } else {
        print("===== token renew went wrong.... login will be retried ======");
        login(localDatabase);
      }
    }).catchError((error) {
      print("===== http request went wrong.... login will be retried ======");
      print(error);
    });

  }

  static void login(SharedPreferences localDatabase) {
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
      "user":{"araras":"false","cpf":cpf,"idMobile":"dummyMobileId","mobileAccess":"true","password":password,"type":"B","version":1}
    };
    String body = json.encode(bodyObject);
    http.post(loginUrl, headers: headers, body: body).then((loginResponse) {
      print("===== login was a success ======");
      Map<String, dynamic> decodedReponseBody = json.decode(loginResponse.body);

      int userId = decodedReponseBody["User"]["id"];
      String authorizationToken = decodedReponseBody["accessToken"];
      String renewToken = decodedReponseBody["refreshToken"];

      localDatabase.setInt(userIdKey, userId);
      localDatabase.setString(authorizationTokenKey, authorizationToken);
      localDatabase.setString(renewTokenKey, renewToken);
    }).catchError((error) {
      print("===== login failed with error: ======");
      print(error);
    });
  }

  static List<SodexoCard> parseSodexoExtractResponse(http.Response sodexoExtractResponse) {
    List<SodexoCard> parsedEntities = new List<SodexoCard>();
    List<dynamic> allCardsJson = json.decode(sodexoExtractResponse.body)["AccountDataReturnV2"];
    allCardsJson.forEach((cardData) {
      SodexoCard sodexoCard = SodexoCard.fromJson(cardData);
      parsedEntities.add(sodexoCard);
    });

    return parsedEntities;
  }

  static bool isRequestSuccessful(int statusCode) {
    return (statusCode ~/ 100) == 2;
  }

}