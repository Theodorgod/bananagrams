import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/controllers/local_game_controller.dart';
import '../game/models/board.dart';
import '../game/models/game_state.dart';
import '../game/models/tile.dart';
import '../game/rules/word_validator.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, this.wordValidator = const WordValidator(words: {})});

  static const routeName = '/game';
  final WordValidator wordValidator;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final LocalGameController _controller;
  late final FocusNode _boardFocusNode;
  BoardPosition? _selectedPosition;
  String? _selectedTileId;

  @override
  void initState() {
    super.initState();
    _controller = LocalGameController(validator: widget.wordValidator);
    _boardFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _boardFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _selectedPosition == null) {
      return KeyEventResult.ignored;
    }

    final current = _selectedPosition!;
    var row = current.row;
    var column = current.column;
    var moved = true;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      row--;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      row++;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      column--;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      column++;
    } else {
      moved = false;
    }

    if (moved) {
      final board = _controller.state.board;
      setState(() {
        _selectedPosition = BoardPosition(
          row.clamp(board.minRow, board.maxRow),
          column.clamp(board.minCol, board.maxCol),
        );
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _controller.removeTile(current);
      return KeyEventResult.handled;
    }

    final letter = event.character?.toUpperCase();
    if (letter == null || letter.length != 1) {
      return KeyEventResult.ignored;
    }

    GameTile? tile;
    for (final availableTile in _controller.state.availableTiles) {
      if (availableTile.letter == letter) {
        tile = availableTile;
        break;
      }
    }
    if (tile == null) {
      return KeyEventResult.ignored;
    }

    _controller.placeTile(tile.id, current);
    return KeyEventResult.handled;
  }

  void _handleSelectTile(String tileId) {
    setState(() {
      _selectedTileId = _selectedTileId == tileId ? null : tileId;
    });
  }

  void _handleThrowTile() {
    final tileId = _selectedTileId;
    if (tileId == null) {
      return;
    }
    _controller.throwTile(tileId);
    setState(() {
      _selectedTileId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Return to Menu'),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: _GameContent(
              state: state,
              onStartGame: _controller.startGame,
              onEndGame: _controller.endGame,
              onPeel: _controller.peel,
              validationError: state.validationError,
              selectedPosition: _selectedPosition,
              boardFocusNode: _boardFocusNode,
              onSelectPosition: (position) {
                final tileId = _selectedTileId;
                setState(() {
                  _selectedPosition = position;
                  _selectedTileId = null;
                });
                if (tileId != null) {
                  _controller.placeTile(tileId, position);
                }
                _boardFocusNode.requestFocus();
              },
              onKeyEvent: _handleKeyEvent,
              selectedTileId: _selectedTileId,
              onSelectTile: _handleSelectTile,
              onThrowTile: _handleThrowTile,
            ),
          ),
        );
      },
    );
  }
}

class _GameContent extends StatelessWidget {
  const _GameContent({
    required this.state,
    required this.onStartGame,
    required this.onEndGame,
    required this.onPeel,
    required this.validationError,
    required this.selectedPosition,
    required this.boardFocusNode,
    required this.onSelectPosition,
    required this.onKeyEvent,
    required this.selectedTileId,
    required this.onSelectTile,
    required this.onThrowTile,
  });

  final GameState state;
  final VoidCallback onStartGame;
  final VoidCallback onEndGame;
  final VoidCallback onPeel;
  final String? validationError;
  final BoardPosition? selectedPosition;
  final FocusNode boardFocusNode;
  final ValueChanged<BoardPosition> onSelectPosition;
  final KeyEventResult Function(KeyEvent) onKeyEvent;
  final String? selectedTileId;
  final ValueChanged<String> onSelectTile;
  final VoidCallback onThrowTile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Center(
          child: FilledButton.icon(
            onPressed: state.isPlaying ? onEndGame : onStartGame,
            icon: Icon(
              state.isPlaying
                  ? Icons.stop_circle_outlined
                  : Icons.play_arrow_rounded,
            ),
            label: Text(state.isPlaying ? 'END GAME' : 'START GAME'),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _TileCountLabel(
                  label: 'Available tiles',
                  count: state.availableTiles.length,
                  tiles: state.availableTiles,
                  alignment: Alignment.topRight,
                  selectedTileId: selectedTileId,
                  onSelectTile: onSelectTile,
                  trailing: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: selectedTileId != null &&
                              state.remainingTiles.isNotEmpty
                          ? onThrowTile
                          : null,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('THROW'),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: KeyboardListener(
                      focusNode: boardFocusNode,
                      onKeyEvent: onKeyEvent,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: state.board.columnCount,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemCount:
                            state.board.rowCount * state.board.columnCount,
                        itemBuilder: (_, index) {
                          final columnCount = state.board.columnCount;
                          final position = BoardPosition(
                            state.board.minRow + index ~/ columnCount,
                            state.board.minCol + index % columnCount,
                          );
                          final tile = state.board.tiles[position];
                          return _BoardCell(
                            tileLetter: tile?.letter,
                            isSelected: selectedPosition == position,
                            onTap: () => onSelectPosition(position),
                            fontSize: (140 / columnCount).clamp(8.0, 20.0),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _TileCountLabel(
                  label: 'Remaining tiles',
                  count: state.remainingTiles.length,
                  tiles: state.remainingTiles,
                  alignment: Alignment.topLeft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(state.elapsed),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF25231F),
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                'Score: ${state.score}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF25231F),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: state.canPeel ? onPeel : null,
          icon: const Icon(Icons.add_box_rounded),
          label: const Text('PEEL'),
        ),
        if (validationError != null) ...[
          const SizedBox(height: 8),
          Text(
            validationError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.tileLetter,
    required this.isSelected,
    required this.onTap,
    required this.fontSize,
  });

  final String? tileLetter;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tileLetter == null
              ? const Color(0xFFFFFDF5)
              : const Color(0xFFFFD447),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF25231F)
                : const Color(0xFFE8D9A8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: tileLetter == null
              ? null
              : Text(
                  tileLetter!,
                  style: TextStyle(
                    color: const Color(0xFF25231F),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TileCountLabel extends StatelessWidget {
  const _TileCountLabel({
    required this.label,
    required this.count,
    required this.tiles,
    required this.alignment,
    this.selectedTileId,
    this.onSelectTile,
    this.trailing,
  });

  final String label;
  final int count;
  final List<GameTile> tiles;
  final Alignment alignment;
  final String? selectedTileId;
  final ValueChanged<String>? onSelectTile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6D665B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF25231F),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (final tile in tiles)
                    _RackTile(
                      letter: tile.letter,
                      isSelected: tile.id == selectedTileId,
                      onTap: onSelectTile == null
                          ? null
                          : () => onSelectTile!(tile.id),
                    ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _RackTile extends StatelessWidget {
  const _RackTile({required this.letter, this.isSelected = false, this.onTap});

  final String letter;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD447),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF25231F)
                : const Color(0xFFE8D9A8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          letter,
          style: const TextStyle(
            color: Color(0xFF25231F),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}