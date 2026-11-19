import 'package:flutter/material.dart';

/// Состояние двери для отображения
enum DoorState {
  closed,       // закрыта, доступна для выбора
  playerChoice, // выбрана игроком (в фазе решения)
  hostOpened,   // открыта ведущим — там коза
  car,          // финальный результат: автомобиль
  losing,       // финальный результат: игрок выбрал проигрышную
}

class DoorWidget extends StatefulWidget {
  final int index;
  final DoorState state;
  final bool interactive;
  final VoidCallback? onTap;
  final Duration revealDelay;
  final bool largeText;

  const DoorWidget({
    super.key,
    required this.index,
    required this.state,
    this.interactive = false,
    this.onTap,
    this.revealDelay = Duration.zero,
    this.largeText = false,
  });

  @override
  State<DoorWidget> createState() => _DoorWidgetState();
}

class _DoorWidgetState extends State<DoorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flip;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flip = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Если дверь уже должна быть открыта при создании — запускаем с задержкой
    if (_shouldReveal(widget.state)) {
      _scheduleReveal();
    }
  }

  @override
  void didUpdateWidget(covariant DoorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_shouldReveal(oldWidget.state) && _shouldReveal(widget.state)) {
      _scheduleReveal();
    } else if (!_shouldReveal(widget.state) && _revealed) {
      // Сброс (новая игра)
      _revealed = false;
      _controller.reset();
    }
  }

  bool _shouldReveal(DoorState s) =>
      s == DoorState.hostOpened || s == DoorState.car || s == DoorState.losing;

  void _scheduleReveal() {
    Future.delayed(widget.revealDelay, () {
      if (!mounted) return;
      setState(() => _revealed = true);
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _bg() {
    switch (widget.state) {
      case DoorState.playerChoice:
        return Colors.indigo.shade100;
      case DoorState.hostOpened:
        return Colors.grey.shade300;
      case DoorState.car:
        return Colors.amber.shade300;
      case DoorState.losing:
        return Colors.red.shade200;
      case DoorState.closed:
        return Colors.blueGrey.shade50;
    }
  }

  Border _border() {
    if (widget.state == DoorState.playerChoice ||
        widget.state == DoorState.car) {
      return Border.all(color: Colors.indigo, width: 2.5);
    }
    return Border.all(color: Colors.black12, width: 1);
  }

  String _label() {
    switch (widget.state) {
      case DoorState.hostOpened:
        return '🐐';
      case DoorState.car:
        return '🚗';
      case DoorState.losing:
        return '🐐';
      case DoorState.playerChoice:
        return '🚪?';
      case DoorState.closed:
        return '🚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pulse = widget.state == DoorState.car ||
        widget.state == DoorState.playerChoice;

    Widget content = AnimatedScale(
      scale: pulse ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            _label(),
            style: TextStyle(fontSize: widget.largeText ? 28 : 12),
          ),
        ),
      ),
    );

    // В момент переворота скрываем содержимое — эффект "обратной стороны"
    content = AnimatedBuilder(
      animation: _flip,
      builder: (context, child) {
        final hidden = _flip.value > 0.5;
        return Opacity(
          opacity: hidden ? 0.0 : 1.0,
          child: child,
        );
      },
      child: content,
    );

    return GestureDetector(
      onTap: widget.interactive ? widget.onTap : null,
      child: MouseRegion(
        cursor: widget.interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _bg(),
            borderRadius: BorderRadius.circular(6),
            border: _border(),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}