class AppConfig {
  // Backend base URL — change via environment or replace for dev builds if needed.
  // Use the canonical backend host with www to avoid HTTP redirects from the server.
  static const String backendBaseUrl = 'https://www.sajilokhel.com';

  // Endpoints
  static String paymentInitiateUrl() => '$backendBaseUrl/api/payment/initiate';
}
