class AppConfig {
  AppConfig._();

  /// Override at run time:
  /// flutter run --dart-define=API_BASE_URL=https://api-dev.ghertak.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// When true, repositories serve tested placeholder data (no live API).
  /// Flip to false (or pass --dart-define=USE_MOCK_DATA=false) when backend is ready.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  static const String appName = 'Gher Tak';
  static const String tagline = 'WE MAKE IT EASY, ALWAYS';
  static const String announcement =
      'Free delivery on orders over Rs. 1,000 · Cash on delivery available';

  static const String defaultVertical = 'grocery';
  static const String currencySymbol = 'Rs.';
}
