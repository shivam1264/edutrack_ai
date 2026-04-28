class Config {
  static const String baseUrl = 'https://edutrack-ai-backend-gt8g.onrender.com';

  static String endpoint(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$baseUrl$path';
  }
}
