class CorsConfig {
  static Map<String, dynamic> get config => {
        'allowed_origins': [
          'http://localhost:8080',
          // 'https://your-frontend.com',
        ],
        'allowed_methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'allowed_headers':
            'Accept, Content-Type, Authorization, X-Requested-With',
      };
}
