import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'shared/widgets/voice_assistant_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar archivo .env
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: TurismoAiApp(),
    ),
  );
}

class TurismoAiApp extends StatelessWidget {
  const TurismoAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turismo AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const VoiceAssistantScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
