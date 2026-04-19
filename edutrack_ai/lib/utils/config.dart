class Config {
  static const String baseUrl = 'https://edutrack-ai-prod.onrender.com';

  static String endpoint(String path) {
    return '$baseUrl$path';
  }
}
