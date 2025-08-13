import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_service.dart';
import 'screens/menu_screen.dart';
import 'models/game_settings.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ImposterApp(),
    ),
  );
}

class ImposterApp extends StatelessWidget {
  const ImposterApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Imposter Game',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system, // Nutzt automatisch das System-Theme
      home: const MenuScreen(),
    );
  }
}

class GameProvider extends ChangeNotifier {
  final GameService _service = GameService();

  GameService get service => _service;

  void updateSettings(GameSettings settings) {
    _service.settings = settings;
    notifyListeners();
  }

  void setPlayers(List<String> names) {
    _service.setupPlayers(names);
    notifyListeners();
  }

  void setImposters(int count) {
    _service.settings = _service.settings.copyWith(imposters: count);
    notifyListeners();
  }

  void updateImposters(int count) {
  _service.settings = _service.settings.copyWith(imposters: count);
  notifyListeners();
  }

  void assignRoles() {
    _service.assignRoles();
    notifyListeners();
  }

  void resetGame() {
    _service.resetGame();
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    notifyListeners();
  }
}
