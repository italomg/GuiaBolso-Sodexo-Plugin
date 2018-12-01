class SodexoTransaction {
  final String codeAuthorization;
  final String description;
  final num balance;
  final String indicatorTransaction;
  final String date;

  SodexoTransaction({this.codeAuthorization, this.description, this.balance, this.indicatorTransaction, this.date});

  factory SodexoTransaction.fromJson(Map<String, dynamic> sodexoTransactionJson) {
    return SodexoTransaction(
        codeAuthorization: sodexoTransactionJson["codeAuthorization"],
        description: sodexoTransactionJson["description"],
        balance: sodexoTransactionJson["balance"],
        indicatorTransaction: sodexoTransactionJson["indicatorTransaction"],
        date: sodexoTransactionJson["date"],
    );
  }
}
