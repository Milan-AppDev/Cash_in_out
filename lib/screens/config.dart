class AppConfig {
  static const String serverIp = '192.168.217.211';
  // static const String serverIp = '127.0.0.1';

  static String get baseUrl => 'http://$serverIp/backend';
  static String get clientsEndpoint => '$baseUrl/clients.php';
  static String get loginEndpoint => '$baseUrl/login.php';
  static String get signupEndpoint => '$baseUrl/signup.php';
  static String get paymentsEndpoint => '$baseUrl/payment.php';
}
