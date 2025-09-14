import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final settings = gameProvider.service.settings;

    return Scaffold(
      appBar: AppBar(title: const Text("Einstellungen")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Kategorie auch bei Zufall anzeigen"),
            value: settings.showCategoryOnRandom,
            onChanged: (val) {
              gameProvider.updateSettings(
                settings.copyWith(showCategoryOnRandom: val),
              );
            },
          ),
          SwitchListTile(
            title: const Text("Timer aktivieren"),
            value: settings.enableTimer,
            onChanged: (val) {
              gameProvider.updateSettings(
                settings.copyWith(enableTimer: val),
              );
            },
          ),

          // eingerückte Zeit-Auswahl
          if (settings.enableTimer)
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text("Zeit pro Spieler"),
                    trailing: DropdownButton<int>(
                      value: settings.timerSeconds,
                      items: [15, 30, 45, 60].map((s) => DropdownMenuItem(
                        value: s,
                        child: Text("$s s"),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          gameProvider.updateSettings(
                            settings.copyWith(timerSeconds: val),
                          );
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Überlegezeit"),
                    trailing: DropdownButton<int>(
                      value: settings.prepareSeconds,
                      items: [10, 15, 20, 30, 60].map((s) => DropdownMenuItem(
                        value: s,
                        child: Text("$s s"),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          gameProvider.updateSettings(
                            settings.copyWith(timerSeconds: val),
                          );
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Pufferzeit"),
                    trailing: DropdownButton<int>(
                      value: settings.bufferSeconds,
                      items: [2, 3, 5, 10].map((s) => DropdownMenuItem(
                        value: s,
                        child: Text("$s s"),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          gameProvider.updateSettings(
                            settings.copyWith(timerSeconds: val),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),


          ListTile(
            title: const Text("Imposter Hinweise"),
            trailing: DropdownButton<String>(
              value: settings.imposterHintsMode,
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(
                  value: "firstOnly",
                  child: Text("Nur wenn erster Spieler"),
                ),
                DropdownMenuItem(
                  value: "always",
                  child: Text("Immer"),
                ),
                DropdownMenuItem(
                  value: "never",
                  child: Text("Nie"),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  gameProvider.updateSettings(
                    settings.copyWith(imposterHintsMode: val),
                  );
                }
              },
            ),
          ),
          SwitchListTile(
            title: const Text("Sound an"),
            value: settings.soundOn,
            onChanged: (val) {
              gameProvider.updateSettings(
                settings.copyWith(soundOn: val),
              );
            },
          ),
          ListTile(
            title: const Text('Darstellung'),
            trailing: DropdownButton<String>(
              value: settings.themeMode,
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Hell')),
                DropdownMenuItem(value: 'dark', child: Text('Dunkel')),
              ],
              onChanged: (val) {
                if (val != null) {
                  gameProvider.updateSettings(settings.copyWith(themeMode: val));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
