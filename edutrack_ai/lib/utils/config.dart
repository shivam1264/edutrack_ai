class Config {
  static const String baseUrl = 'https://edutrack-ai-prod.onrender.com';

  static String endpoint(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$baseUrl$path';
  }
}
