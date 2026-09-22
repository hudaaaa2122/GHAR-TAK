class AppConfig {
  AppConfig._();

  /// Override at run time:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  /// Physical device (local): use your PC LAN IP, e.g. http://192.168.1.10:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ghertak.com',
  );

  /// When true, repositories serve placeholder data (offline / demo).
  /// Default false on `align-api` so the app talks to FastAPI.
  /// flutter run --dart-define=USE_MOCK_DATA=true
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  static const String appName = 'Gher Tak';
  static const String tagline = 'WE MAKE IT EASY, ALWAYS';

  /// Fallback only — prefer [settingsProvider] / live `/settings` values.
  static const String announcement =
      'Free delivery on orders over Rs. 3,000 · Cash on delivery available';

  /// Fallback free-shipping threshold when settings API is unavailable.
  static const double defaultFreeShippingAmount = 3000;

  static const String defaultVertical = 'grocery';
  static const String currencySymbol = 'Rs.';

  /// Web OAuth client ID — must match backend `GOOGLE_CLIENT_ID` (used as
  /// `serverClientId` so Android/iOS receive an `id_token` for `/google`).
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '375898179358-pnst0277v4jugtu5bn2t6t1pom6g8edt.apps.googleusercontent.com',
  );
}
