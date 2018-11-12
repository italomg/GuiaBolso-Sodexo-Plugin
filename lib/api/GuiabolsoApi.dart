import 'package:guiabolso_plugin_sodexo/model/SodexoTransaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuiabolsoApi {
  String email;
  String cpf;
  SharedPreferences localDatabase;

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

  }
}