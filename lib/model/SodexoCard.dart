import 'package:guiabolso_plugin_sodexo/model/SodexoTransaction.dart';
import 'package:guiabolso_plugin_sodexo/api/GuiabolsoApi.dart';

class SodexoCard {
  final String productCode;
  final List<SodexoTransaction> sodexoTransactions;
  static const Map<String, String> PRODUCT_TO_TYPE = {
    "4030": GuiabolsoApi.SODEXO_COMBUSTIVEL_STATEMENT_KEY,
    "6001": GuiabolsoApi.SODEXO_REFEICAO_STATEMENT_KEY,
    "6002": GuiabolsoApi.SODEXO_ALIMENTACAO_STATEMENT_KEY,
  };

  SodexoCard({this.productCode, this.sodexoTransactions});

  factory SodexoCard.fromJson(Map<String, dynamic> sodexoCardJson) {
    List<SodexoTransaction> sodexoTransactionList = new List<SodexoTransaction>();
    List<dynamic> sodexoTransactionsJson = sodexoCardJson["TransactionDataReturn"];
    sodexoTransactionsJson.forEach((sodexoTransactionJson) {
      sodexoTransactionList.add(SodexoTransaction.fromJson(sodexoTransactionJson));
    });

    return SodexoCard(productCode: sodexoCardJson["productCode"], sodexoTransactions: sodexoTransactionList);
  }

}