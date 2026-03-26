class AppConfig {
  static const String mapTileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const String mapAttribution = String.fromEnvironment(
    'MAP_ATTRIBUTION',
    defaultValue: 'Map tiles © OpenStreetMap contributors',
  );

  static const String mapUserAgentPackage = String.fromEnvironment(
    'MAP_USER_AGENT',
    defaultValue: 'com.example.women_safety',
  );
}

class Config {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Auth Token (will be set after login)
  static String authToken = '';

  // Emergency Services Numbers (India)
  static const String policeNumber = '100';
  static const String ambulanceNumber = '102';
  static const String womenHelplineNumber = '181';
  static const String emergencyNumber = '112';

  // SOS Configuration
  static const Duration recordingDuration = Duration(seconds: 30);
  static const int maxEmergencyContacts = 5;

  // Shake Detection Configuration
  static const double shakeThreshold = 20.0; // m/s²
  static const int shakeCountRequired = 3;

  // Voice Activation Keywords
  static const List<String> emergencyKeywords = [
    'help me',
    'help',
    'emergency',
    'sos',
    'danger',
    'save me',
  ];

  // Backend API Configuration (for automatic SMS)
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String backendApiKey = String.fromEnvironment(
    'BACKEND_API_KEY',
    defaultValue: '',
  );

  // SMS Gateway API Keys (for automatic SMS sending)
  
  // Fast2SMS (India only) - Get free API key: https://www.fast2sms.com/
  // Free plan: 100 SMS/day
  static const String fast2smsApiKey = String.fromEnvironment(
    'FAST2SMS_API_KEY',
    defaultValue: '',
  );
  
  // Twilio (Global) - Get account: https://www.twilio.com/
  // Pay per SMS: ~$0.0075/SMS (~₹0.60 per SMS)
  static const String twilioAccountSid = String.fromEnvironment(
    'TWILIO_ACCOUNT_SID',
    defaultValue: '',
  );
  static const String twilioAuthToken = String.fromEnvironment(
    'TWILIO_AUTH_TOKEN',
    defaultValue: '',
  );
  static const String twilioFromNumber = String.fromEnvironment(
    'TWILIO_FROM_NUMBER',
    defaultValue: '',
  );

  // Agora (Live Streaming)
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );
  static const String agoraTempToken = String.fromEnvironment(
    'AGORA_TEMP_TOKEN',
    defaultValue: '',
  );

  // Feature flags (enable explicitly for production)
  static const bool enableLiveStreaming = bool.fromEnvironment(
    'FEATURE_LIVE_STREAMING',
    defaultValue: false,
  );
  static const bool enableGuardianNetwork = bool.fromEnvironment(
    'FEATURE_GUARDIAN_NETWORK',
    defaultValue: true,
  );
  static const bool enableFaceRecognition = bool.fromEnvironment(
    'FEATURE_FACE_RECOGNITION',
    defaultValue: true,
  );
  static const bool enableVoiceDistress = bool.fromEnvironment(
    'FEATURE_VOICE_DISTRESS',
    defaultValue: true,
  );
  static const bool enableAIDangerPrediction = bool.fromEnvironment(
    'FEATURE_AI_DANGER',
    defaultValue: true,
  );

  static bool get isLiveStreamingEnabled =>
      enableLiveStreaming && agoraAppId.isNotEmpty;
  static bool get isGuardianNetworkEnabled => enableGuardianNetwork;
  static bool get isFaceRecognitionEnabled => enableFaceRecognition;
  static bool get isVoiceDistressEnabled => enableVoiceDistress;
  static bool get isAIDangerPredictionEnabled => enableAIDangerPrediction;

  static String? get liveStreamingDisabledReason {
    if (!enableLiveStreaming) {
      return 'Set FEATURE_LIVE_STREAMING=true via --dart-define';
    }
    if (agoraAppId.isEmpty) {
      return 'Configure AGORA_APP_ID via --dart-define';
    }
    return null;
  }

  static String? get guardianNetworkDisabledReason {
    if (!enableGuardianNetwork) {
      return 'Set FEATURE_GUARDIAN_NETWORK=true via --dart-define';
    }
    return null;
  }

  static String? get faceRecognitionDisabledReason {
    if (!enableFaceRecognition) {
      return 'Set FEATURE_FACE_RECOGNITION=true via --dart-define';
    }
    return null;
  }

  static String? get voiceDistressDisabledReason {
    if (!enableVoiceDistress) {
      return 'Set FEATURE_VOICE_DISTRESS=true via --dart-define';
    }
    return null;
  }

  static String? get aiDangerDisabledReason {
    if (!enableAIDangerPrediction) {
      return 'Set FEATURE_AI_DANGER=true via --dart-define';
    }
    return null;
  }

  static int get enabledRevolutionaryFeatureCount {
    var count = 3; // Fake Call, Panic Widget and Ride Tracking are always enabled.
    if (isLiveStreamingEnabled) count++;
    if (isGuardianNetworkEnabled) count++;
    if (isFaceRecognitionEnabled) count++;
    if (isVoiceDistressEnabled) count++;
    if (isAIDangerPredictionEnabled) count++;
    return count;
  }

  // Update auth token after login
  static void setAuthToken(String token) {
    authToken = token;
  }

  // Clear auth token on logout
  static void clearAuthToken() {
    authToken = '';
  }
}
