/// App-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Soft POS Demo';
  static const String appVersion = '1.0.0';
  
  // Currency
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // NFC
  static const Duration nfcTimeout = Duration(seconds: 30);
  static const Duration processingDelay = Duration(seconds: 1);
  
  // UI
  static const double defaultPadding = 20.0;
  static const double defaultMargin = 16.0;
  static const double defaultRadius = 15.0;
}