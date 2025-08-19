import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'shared/widgets/map_with_voice_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando Turismo AI...');
  
  try {
    // Cargar archivo .env
    await dotenv.load(fileName: ".env");
    print('✅ Archivo .env cargado correctamente');
    
    // Verificar API keys
    final geoapifyKey = dotenv.env['GEOAPIFY_API_KEY'];
    final openaiKey = dotenv.env['OPENAI_API_KEY'];
    
    if (geoapifyKey != null && geoapifyKey.isNotEmpty) {
      print('✅ API Key de Geoapify encontrada');
    } else {
      print('⚠️ API Key de Geoapify no encontrada en .env');
    }
    
    if (openaiKey != null && openaiKey.isNotEmpty) {
      print('✅ API Key de OpenAI encontrada');
    } else {
      print('⚠️ API Key de OpenAI no encontrada en .env');
    }
    
  } catch (e) {
    print('❌ Error cargando .env: $e');
    print('⚠️ API Keys no configuradas - crea un archivo .env');
  }
  
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
      home: const MapWithVoiceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

