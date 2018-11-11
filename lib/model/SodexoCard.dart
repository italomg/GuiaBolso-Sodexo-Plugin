import 'package:guiabolso_plugin_sodexo/model/SodexoTransaction.dart';

class SodexoCard {
  final String productCode;
  final List<SodexoTransaction> sodexoTransactions;

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