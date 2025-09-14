import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player.dart';
import 'game_summary_screen.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({super.key});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  // Aktive Spieler (Reihenfolge startet beim Startspieler)
  final List<Player> _activePlayers = [];

  int _currentPlayerIndex = 0;
  int _round = 1;

  // Timer / Anzeige
  int _timeLeft = 0;
  int _maxTime = 0;
  Timer? _timer;
  bool _paused = false;

  // Phasen: prepare (15s Überlegezeit), play (settings.timerSeconds), buffer (5s), discussion
  String _phase = 'prepare';

  @override
  void initState() {
    super.initState();

    // Spielerdaten & Startspieler aus GameProvider übernehmen
    final service = context.read<GameProvider>().service;
    _activePlayers.addAll(service.players);

    // Wenn es einen Startspieler-Index gibt, rotieren wir die Liste so, dass er vorne ist
    if (service.startPlayerIndex != null &&
        service.startPlayerIndex! >= 0 &&
        service.startPlayerIndex! < _activePlayers.length) {
      final start = service.startPlayerIndex!;
      final rotated = [
        ..._activePlayers.sublist(start),
        ..._activePlayers.sublist(0, start),
      ];
      _activePlayers
        ..clear()
        ..addAll(rotated);
    }

    // Vorbereitung (Überlegezeit) starten
    _startPreparePhase();
  }

  // ─── Phase-Start-Methoden ───────────────────────────────────────────────────
  void _startPreparePhase() {
    final settings = context.read<GameProvider>().service.settings;
    setState(() {
      _phase = 'prepare';
      _maxTime = settings.prepareSeconds;
      _timeLeft = _maxTime;
      _paused = false;
    });
    _startSecondTimer(() {
      _startPlayPhase(settings.timerSeconds);
    });
  }

  void _startPlayPhase(int seconds) {
    if (_activePlayers.isEmpty) {
      _startDiscussionPhase();
      return;
    }
    setState(() {
      _phase = 'play';
      _maxTime = seconds;
      _timeLeft = _maxTime;
      _paused = false;
    });
    _startSecondTimer(() {
      _startBufferPhase();
    });
  }

  void _startBufferPhase() {
    final settings = context.read<GameProvider>().service.settings;

    if (_currentPlayerIndex >= _activePlayers.length - 1) {
      _startDiscussionPhase();
      return;
    }

    setState(() {
      _phase = 'buffer';
      _maxTime = settings.bufferSeconds;
      _timeLeft = _maxTime;
      _paused = false;
    });

    _startSecondTimer(() {
      setState(() {
        _currentPlayerIndex++;
      });
      _startPlayPhase(settings.timerSeconds);
    });
  }

  void _startDiscussionPhase() {
    setState(() {
      _phase = 'discussion';
      _maxTime = 0;
      _timeLeft = 0;
      _paused = false;
    });
    // Keine automatische Aktion: Diskussion ist Pause ohne Timer. (kein "Nächste Runde"-Button hier)
  }

  void _startNextRound() {
    setState(() {
      _round++;
      _currentPlayerIndex = 0; 
    });
    _startPreparePhase();
  }

  // ─── Timer Hilfsfunktionen ───────────────────────────────────────────────────
  void _startSecondTimer(VoidCallback onFinished) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paused) return;
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        onFinished();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
  }

  // ─── Aktionen: Vorspulen (skip), Spieler entfernen ───────────────────────────
  /// Vorspulen: beendet die aktuelle Phase sofort und springt weiter
  void _skipPhase() {
    _cancelTimer();

    final settings = context.read<GameProvider>().service.settings;

    switch (_phase) {
      case 'prepare':
        _startPlayPhase(settings.timerSeconds);
        break;
      case 'play':
        // 👉 Wenn letzter Spieler, direkt Diskussion
        if (_currentPlayerIndex >= _activePlayers.length - 1) {
          _startDiscussionPhase();
        } else {
          _startBufferPhase();
        }
        break;
      case 'buffer':
        if (_currentPlayerIndex < _activePlayers.length - 1) {
          setState(() {
            _currentPlayerIndex++;
          });
          _startPlayPhase(settings.timerSeconds);
        } else {
          // 👉 Letzter Spieler → Diskussion
          _startDiscussionPhase();
        }
        break;
      case 'discussion':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diskussion läuft — Auflösen oder nächste Runde starten.')),
        );
    }
  }

  /// Entfernt den aktuell aktiven Spieler (mit Bestätigung).
  void _confirmRemoveCurrentPlayer() async {
    if (_activePlayers.isEmpty) return;
    final current = _activePlayers[_currentPlayerIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Spieler entfernen'),
        content: Text('Soll ${current.name} wirklich entfernt werden?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Entfernen')),
        ],
      ),
    );

    if (confirmed == true) {
      _removeCurrentPlayerAfterConfirm();
    }
  }

  void _removeCurrentPlayerAfterConfirm() {
    if (_activePlayers.isEmpty) return;

    _cancelTimer();

    setState(() {
      _activePlayers.removeAt(_currentPlayerIndex);
      if (_currentPlayerIndex >= _activePlayers.length) {
        _currentPlayerIndex = 0;
      }
    });

    if (_activePlayers.isEmpty) {
      _startDiscussionPhase();
    } else {
      // Wir starten die Pufferphase, damit zwischen Removal und dem nächsten Spieler
      // eine kurze Pause besteht.
      _startBufferPhase();
    }
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final Player? currentPlayer = _activePlayers.isNotEmpty ? _activePlayers[_currentPlayerIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Runde $_round'),
        actions: [
          if (currentPlayer != null && _phase == 'play')
            IconButton(
              icon: const Icon(Icons.person_remove),
              tooltip: 'Spieler entfernen',
              onPressed: _confirmRemoveCurrentPlayer,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // Oben: Spielername / Phase
            if (_phase == 'play' && currentPlayer != null) ...[
              Text(
                '${currentPlayer.name} ist dran!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ] else if (_phase == 'prepare') ...[
              const Text(
                'Überlegezeit',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ] else if (_phase == 'buffer') ...[
              const Text(
                'Nächster Spieler gleich…',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ] else if (_phase == 'discussion') ...[
              const Text(
                'Diskussion!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 28),

            // Timer-Kreis nur, wenn es auch Zeit gibt
            Expanded(
              child: Center(
                child: (_phase == 'discussion')
                    ? const SizedBox.shrink() // kein Kreis, keine Texte
                    : _buildTimerCircle(),
              ),
            ),

            const SizedBox(height: 18),

            if (_phase != 'discussion') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _togglePause,
                    icon: Icon(
                      _paused ? Icons.play_arrow : Icons.pause,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    onPressed: _skipPhase,
                    icon: const Icon(
                      Icons.fast_forward,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 200),
                ],
              ),
            ] else if (_phase == 'discussion') ...[
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 220,  // Breite etwas kleiner für besseren Fit
                    height: 70,  // Höhe passend zur Breite
                    child: ElevatedButton.icon(
                      onPressed: _startNextRound,
                      icon: const Icon(Icons.refresh, size: 28),  // Icon etwas kleiner
                      label: const Flexible(
                        child: Text(
                          'Nächste Runde starten',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.visible,  // Text wird nicht abgeschnitten
                          textAlign: TextAlign.center,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],


            const SizedBox(height: 16),

            // Ganz unten: Auflösen
            Padding(
              padding: const EdgeInsets.only(bottom: 18, left: 16, right: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const GameSummaryScreen()),
                    );
                  },
                  child: const Text('Auflösen', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Timer-Kreis-Widget ────────────────────────────────────────────────────
  Widget _buildTimerCircle() {
    final double progress = (_maxTime > 0) ? (_timeLeft / _maxTime) : 0.0;

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kreis (aktueller Fortschritt)
          SizedBox(
            width: 300,
            height: 300,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 18,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),

          // Restzeit in Sekunden
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_timeLeft s',
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _phase == 'prepare' ? 'Überlegezeit' : (_phase == 'buffer' ? 'Puffer' : 'Verbleibend'),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
