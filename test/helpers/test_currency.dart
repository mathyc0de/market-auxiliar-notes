import 'package:intl/intl.dart';

NumberFormat testCurrency() {
  return NumberFormat.currency(symbol: 'R\$', locale: 'pt_BR');
}
