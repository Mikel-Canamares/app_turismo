class AppConstants {
  // API URLs
  static const String openTripMapBaseUrl = 'https://api.opentripmap.com/0.1';
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String anthropicBaseUrl = 'https://api.anthropic.com';

  // Default values
  static const int defaultSearchRadius = 1000; // metros
  static const int maxPlacesLimit = 10;
  static const String defaultLanguage = 'es';

  // Speech settings
  static const double speechRate = 0.5;
  static const double speechVolume = 1.0;
  static const double speechPitch = 1.0;

  // Messages
  static const String welcomeMessage = 
      'Hola, soy tu asistente de turismo. Te ayudaré a descubrir lugares increíbles cerca de ti. ¿Qué te gustaría saber?';
  
  static const String noLocationMessage = 
      'No pude obtener tu ubicación. ¿Podrías decirme en qué ciudad te encuentras?';
  
  static const String noPlacesFoundMessage = 
      'No encontré lugares de interés cerca de ti, pero dime qué tipo de lugar te interesa y te ayudo a encontrarlo.';
  
  static const String errorMessage = 
      'Disculpa, hubo un problema. ¿Puedes repetir tu pregunta?';

  // Permissions messages
  static const String locationPermissionDenied = 
      'Necesito acceso a tu ubicación para encontrar lugares cerca de ti. ¿Puedes habilitarlo en configuración?';
  
  static const String microphonePermissionDenied = 
      'Necesito acceso al micrófono para escucharte. ¿Puedes habilitarlo en configuración?';
}
