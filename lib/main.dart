import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/game_service.dart';
import 'screens/menu_screen.dart';
import 'models/game_settings.dart';
import 'services/category_service.dart';
import 'services/ad_service.dart';
import 'services/unlock_service.dart';

// Farben
const Color kLightBackground = Colors.white;
const Color kDarkBackground = Colors.black;
const MaterialColor kPrimarySwatch = Colors.blue;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gameService = GameService();
  await gameService.loadSettings();

  final categoryService = CategoryService(gameService.settings);
  await categoryService.init();

  final adService = AdService();
  final unlockService = UnlockService(gameService.settings);
  await unlockService.loadUnlocked();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider(gameService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => categoryService),
        ChangeNotifierProvider(create: (_) => adService),
        ChangeNotifierProvider(create: (_) => unlockService),
      ],
      child: const ImposterApp(),
    ),
  );
}


class ImposterApp extends StatelessWidget {
  const ImposterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final settings = gameProvider.service.settings;

        ThemeMode themeMode;
        switch (settings.themeMode) {
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          case 'light':
            themeMode = ThemeMode.light;
            break;
          default:
            themeMode = ThemeMode.system;
        }

        return MaterialApp(
          title: 'Imposter Game',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            // Dynamische Systemleisten-Farbe passend zum Theme
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: theme.scaffoldBackgroundColor,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
            );

            return Container(
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                top: true,
                bottom: true,
                left: false,
                right: false,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },

          // LIGHT THEME
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: kLightBackground,
            primarySwatch: kPrimarySwatch,
            appBarTheme: const AppBarTheme(
              backgroundColor: kLightBackground,
              elevation: 0,
              foregroundColor: Colors.black,
              surfaceTintColor: Colors.transparent, // 🔹 wichtig
            ),


            // HIER: Nur das Popup-Menü runden (aufgeklapptes Menü)
            dropdownMenuTheme: DropdownMenuThemeData(
              menuStyle: MenuStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // falls du die Popup-Hintergrundfarbe setzen willst:
                backgroundColor: WidgetStatePropertyAll(kLightBackground),
              ),
            ),
          ),

          // DARK THEME
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kDarkBackground,
            primarySwatch: kPrimarySwatch,
            appBarTheme: const AppBarTheme(
              backgroundColor: kDarkBackground,
              elevation: 0,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent, // 🔹
            ),

            dropdownMenuTheme: DropdownMenuThemeData(
              menuStyle: MenuStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                backgroundColor: WidgetStatePropertyAll(kDarkBackground),
              ),
            ),
          ),

          themeMode: themeMode,
          home: const MenuScreen(),
        );
      },
    );
  }
}

// --- Provider-Klassen bleiben unverändert ---
class GameProvider extends ChangeNotifier {
  final GameService _service;
  GameProvider(this._service);

  GameService get service => _service;

  bool get isSoundOn => _service.settings.soundOn;

  void updateSettings(GameSettings settings) {
    _service.updateSettings(settings);
    notifyListeners();
  }

  void setPlayers(List<String> names) {
    _service.setupPlayers(names);
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

  void playSoundIfEnabled(void Function() play) {
    if (isSoundOn) play();
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
