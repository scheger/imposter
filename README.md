# imposter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



Ich arbeite an einem Partyspiel namens „Imposter Game“, das ich in Flutter entwickle.
Das Spiel ist lokal auf einem Gerät spielbar (ohne Online-Modus) und funktioniert so:

Die Spieler geben ihre Namen ein.
Ein oder mehrere Spieler werden zufällig als Imposter bestimmt.
Das Spiel zeigt für alle Spieler (nacheinander) geheime Begriffe oder Fragen an.
Die Crew sieht denselben Begriff, die Imposter sehen einen leicht anderen oder ähnlichen.
Danach diskutieren alle, wer der Imposter ist.

Struktur:
    main.dart
    service
        - ad_service.dart           Verwaltet Werbung (Google Mobile Ads) (nicht implimentiert)
        - category_service.dart     Lädt und verwaltet die verfügbaren Themen und Wortlisten.
        - game_service.dart         Verwaltet Spieler, Rollenverteilung, Spielmodus (classic, similar, undercover),sowie das Speichern und Laden der GameSettings über SharedPreferences.
        - unlock_service.dart
    models
        - game_settings.dart        speichert Einstellungen (z. B. Sound, Theme, Imposter-Anzahl, Modus, unlockedFeatures).
        - player.dart
        - words.dart
    screens
        - menu_screen.dart              Hauptmenü
        - settings_screen.dart          Einstellung Menu
        - mode_selection_screen.dart    Spielmoduswahl
        - theme_selection_screen.dart   Themenauswahl (Wörter/Fragen)
        - player_setup_screen.dart      Namenseingabe und Imposteranzahl
        - role_reveal_screen.dart       Roleverteilung
        - game_play_screen.dart
        - game_summery_screen.dart      
    models
        images
            - logo.png
        questions
            - fun.json
            - ...
        words
            - animals.json
            - ...
.