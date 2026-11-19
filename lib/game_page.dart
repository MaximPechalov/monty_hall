import 'dart:math';
import 'package:flutter/material.dart';
import 'door_widget.dart';

enum Phase { choosing, deciding, result }

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Random _rnd = Random();

  int _doorCount = 3;
  int _carDoor = 0;
  int _playerChoice = -1;
  Set<int> _hostOpenedDoors = {};
  Phase _phase = Phase.choosing;
  bool? _won;
  bool _switched = false;

  // Статистика
  int _playedStay = 0, _wonStay = 0;
  int _playedSwitch = 0, _wonSwitch = 0;
  int _switchWhenCorrect = 0; // сменил, изначально угадав → проигрыш

  int _gridEpoch = 0;

  void _startNewGame() {
    setState(() {
      _carDoor = _rnd.nextInt(_doorCount);
      _playerChoice = -1;
      _hostOpenedDoors = {};
      _phase = Phase.choosing;
      _won = null;
      _switched = false;
      _gridEpoch++;
    });
  }

  void _chooseDoor(int door) {
    if (_phase != Phase.choosing) return;

    // Ведущий открывает РОВНО N-2 дверей с козами:
    // все, кроме выбора игрока и двери с автомобилем.
    final candidatesForHost = <int>[];
    for (int d = 0; d < _doorCount; d++) {
      if (d != door && d != _carDoor) candidatesForHost.add(d);
    }

    // Нужно открыть N-2. Если кандидатов больше (то есть игрок угадал,
    // и автомобиль за его дверью), выбираем случайное подмножество N-2.
    final opened = <int>{};
    if (candidatesForHost.length <= _doorCount - 2) {
      opened.addAll(candidatesForHost);
    } else {
      candidatesForHost.shuffle(_rnd);
      opened.addAll(candidatesForHost.take(_doorCount - 2));
    }

    setState(() {
      _playerChoice = door;
      _hostOpenedDoors = opened;
      _phase = Phase.deciding;
    });
  }

  /// Единственная свободная закрытая дверь, кроме выбора игрока
  int _freeDoor() {
    return List.generate(_doorCount, (i) => i).firstWhere(
      (d) => d != _playerChoice && !_hostOpenedDoors.contains(d),
    );
  }

  void _decide(bool switchDoor) {
    if (_phase != Phase.deciding) return;

    int finalChoice = _playerChoice;
    if (switchDoor) {
      finalChoice = _freeDoor();
    }
    final won = finalChoice == _carDoor;

    setState(() {
      _won = won;
      _switched = switchDoor;
      _phase = Phase.result;
      if (switchDoor) {
        _playedSwitch++;
        if (won) _wonSwitch++;
        if (_playerChoice == _carDoor) _switchWhenCorrect++;
      } else {
        _playedStay++;
        if (won) _wonStay++;
      }
    });
  }

  DoorState _doorState(int i) {
    if (_phase == Phase.result) {
      if (i == _carDoor) return DoorState.car;
      if (i == _playerChoice && !_won!) return DoorState.losing;
      if (_hostOpenedDoors.contains(i)) return DoorState.hostOpened;
      return DoorState.closed;
    }
    if (_phase == Phase.deciding) {
      if (i == _playerChoice) return DoorState.playerChoice;
      if (_hostOpenedDoors.contains(i)) return DoorState.hostOpened;
    }
    return DoorState.closed;
  }

  Duration _revealDelay(int i) {
    final stepMs = _doorCount <= 12
        ? 60
        : _doorCount <= 100
            ? 15
            : 1;
    return Duration(milliseconds: i * stepMs);
  }

  int _crossAxisCount() {
    if (_doorCount <= 12) return 4;
    if (_doorCount <= 100) return 10;
    return 25;
  }

  String _phaseHint() {
    switch (_phase) {
      case Phase.choosing:
        return 'Выберите дверь. Автомобиль спрятан за одной из $_doorCount.';
      case Phase.deciding:
        return 'Ведущий открыл ${_hostOpenedDoors.length} двер(ей) с козами. '
            'Осталась одна свободная — можно сменить.';
      case Phase.result:
        return _won! ? '🎉 Победа! Это был автомобиль.' : '😢 Увы, коза.';
    }
  }

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Парадокс Монти Холла')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Дверей:'),
                Expanded(
                  child: Slider(
                    value: _doorCount.toDouble(),
                    min: 3,
                    max: 1000,
                    divisions: 997,
                    label: '$_doorCount',
                    onChanged: _phase == Phase.choosing
                        ? (v) {
                            _doorCount = v.round();
                            _startNewGame();
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text('$_doorCount', textAlign: TextAlign.end),
                ),
              ],
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                key: ValueKey(_phase),
                _phaseHint(),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: GridView.builder(
                  key: ValueKey(_gridEpoch),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _doorCount,
                  itemBuilder: (context, i) {
                    return DoorWidget(
                      key: ValueKey('door_$i'),
                      index: i,
                      state: _doorState(i),
                      interactive: _phase == Phase.choosing,
                      onTap: () => _chooseDoor(i),
                      revealDelay: _revealDelay(i),
                      largeText: _doorCount <= 12,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _phase == Phase.deciding
                  ? Offset.zero
                  : const Offset(0, 0.3),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _phase == Phase.deciding ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: _phase != Phase.deciding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton(
                        onPressed: () => _decide(false),
                        child: const Text('Остаться'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _decide(true),
                        child: const Text('Сменить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _phase == Phase.result
                  ? Offset.zero
                  : const Offset(0, 0.3),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _phase == Phase.result ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: _phase != Phase.result,
                  child: FilledButton(
                    onPressed: _startNewGame,
                    child: const Text('Сыграть ещё'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Остался: $_wonStay/$_playedStay   |   '
              'Сменил: $_wonSwitch/$_playedSwitch   |   '
              'Смена при угаданном: $_switchWhenCorrect',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}