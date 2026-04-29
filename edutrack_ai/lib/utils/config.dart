class Config {
  // static const String baseUrl = 'https://edutrack-ai-backend-gt8g.onrender.com';
  static const String baseUrl = 'http://10.44.40.102:5000';

  static String endpoint(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$baseUrl$path';
  }
}
