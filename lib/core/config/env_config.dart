enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  final Environment environment;
  final String apiUrl;
  final String wsUrl;

  EnvConfig({
    required this.environment,
    required this.apiUrl,
    required this.wsUrl,
  });

  static EnvConfig get development => EnvConfig(
        environment: Environment.development,
        apiUrl: 'http://localhost:5001',
        wsUrl: 'ws://localhost:5001',
      );

  static EnvConfig get production => EnvConfig(
        environment: Environment.production,
        apiUrl: 'https://api.messenger-bottle.com',
        wsUrl: 'wss://api.messenger-bottle.com',
      );
}
