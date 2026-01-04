class AppConfig {
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  
  // Decoupled keys for legacy support if needed
  static const String geminiApiKey = openAiApiKey;
  static const String scannerApiKey = openAiApiKey;
}
