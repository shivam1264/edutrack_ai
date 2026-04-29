class Config {
  static const String baseUrl = 'https://edutrack-ai-backend-gt8g.onrender.com';
  // static const String baseUrl = 'http://10.140.129.97:8080';

  static String endpoint(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$baseUrl$path';
  }
}
