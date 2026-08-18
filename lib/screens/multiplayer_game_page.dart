import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/models/board.dart';
import '../game/models/tile.dart';
import '../game/network/multiplayer_models.dart';

/// Shared game board UI, driven by either a hosted game or a joined one.
/// Mirrors single-player controls: click a cell to select it, then type a
/// letter to place a matching tile there, or press backspace to remove it.
class MultiplayerGamePage extends StatefulWidget {
  const MultiplayerGamePage({super.key, required this.controller});

  static const routeName = '/multiplayer/game';
  final MultiplayerController controller;

  @override
  State<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends State<MultiplayerGamePage> {
  late final FocusNode _boardFocusNode;
  BoardPosition? _selectedPosition;
  String? _selectedTileId;

  @override
  void initState() {
    super.initState();
    _boardFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _boardFocusNode.dispose();
    widget.controller.dispose();
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
      final board = widget.controller.multiplayerState.board;
      setState(() {
        _selectedPosition = BoardPosition(
          row.clamp(board.minRow, board.maxRow),
          column.clamp(board.minCol, board.maxCol),
        );
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      widget.controller.removeTile(current);
      return KeyEventResult.handled;
    }

    final letter = event.character?.toUpperCase();
    if (letter == null || letter.length != 1) {
      return KeyEventResult.ignored;
    }

    GameTile? tile;
    for (final availableTile in widget.controller.multiplayerState.availableTiles) {
      if (availableTile.letter == letter) {
        tile = availableTile;
        break;
      }
    }
    if (tile == null) {
      return KeyEventResult.ignored;
    }

    widget.controller.placeTile(tile.id, current);
    return KeyEventResult.handled;
  }

  void _handleSelectPosition(BoardPosition position) {
    final tileId = _selectedTileId;
    setState(() {
      _selectedPosition = position;
      _selectedTileId = null;
    });
    if (tileId != null) {
      widget.controller.placeTile(tileId, position);
    }
    _boardFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.multiplayerState;

        return Scaffold(
          appBar: AppBar(
            title: const Text('LAN Game'),
            leading: ExcludeFocusTraversal(
              child: IconButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Leave game',
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Tiles left in pool: ${state.poolCount}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _Scoreboard(players: state.players),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: KeyboardListener(
                              focusNode: _boardFocusNode,
                              onKeyEvent: _handleKeyEvent,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: state.board.columnCount,
                                  crossAxisSpacing: 5,
                                  mainAxisSpacing: 5,
                                ),
                                itemCount: state.board.rowCount *
                                    state.board.columnCount,
                                itemBuilder: (_, index) {
                                  final columnCount = state.board.columnCount;
                                  final position = BoardPosition(
                                    state.board.minRow + index ~/ columnCount,
                                    state.board.minCol + index % columnCount,
                                  );
                                  final tile = state.board.tiles[position];
                                  return _MPBoardCell(
                                    tileLetter: tile?.letter,
                                    isSelected: _selectedPosition == position,
                                    fontSize:
                                        (140 / columnCount).clamp(8.0, 20.0),
                                    onTap: () => _handleSelectPosition(position),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                Text(
                                  'Your tiles',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 3,
                                  runSpacing: 3,
                                  children: [
                                    for (final tile in state.availableTiles)
                                      _MPRackTile(
                                        letter: tile.letter,
                                        isSelected: tile.id == _selectedTileId,
                                        onTap: () => setState(() {
                                          _selectedTileId =
                                              _selectedTileId == tile.id
                                                  ? null
                                                  : tile.id;
                                        }),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _selectedTileId != null &&
                                          state.poolCount > 0
                                      ? () {
                                          widget.controller
                                              .throwTile(_selectedTileId!);
                                          setState(() => _selectedTileId = null);
                                        }
                                      : null,
                                  icon: const Icon(Icons.delete_sweep_outlined),
                                  label: const Text('THROW'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state.canPeel ? widget.controller.peel : null,
                  icon: const Icon(Icons.add_box_rounded),
                  label: const Text('PEEL'),
                ),
                if (state.validationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.validationError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.players});

  final List<PlayerInfo> players;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Players',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final player in players)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${player.name}: '
                '${player.score} pts (${player.tilesLeft} tiles)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MPBoardCell extends StatelessWidget {
  const _MPBoardCell({
    required this.tileLetter,
    required this.isSelected,
    required this.fontSize,
    required this.onTap,
  });

  final String? tileLetter;
  final bool isSelected;
  final double fontSize;
  final VoidCallback onTap;

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

class _MPRackTile extends StatelessWidget {
  const _MPRackTile({
    required this.letter,
    required this.isSelected,
    required this.onTap,
  });

  final String letter;
  final bool isSelected;
  final VoidCallback onTap;

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
