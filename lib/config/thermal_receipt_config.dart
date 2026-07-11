import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';

/// Configuração global do recibo térmico.
class ThermalReceiptConfig {
  ThermalReceiptConfig._();

  /// Caminho do logo no bundle (ex.: assets/logo.png). Vazio oculta o logo.
  static const String logoAssetPath = 'assets/logo.png';
  static const String marketNamePlaceholder = 'Fruteira DR';

  /// Papel 58mm (384 dots). Para 80mm, use 576 e PaperSize.mm80.
  static const int paperDots = 384;
  static const PaperSize paperSize = PaperSize.mm58;
}
