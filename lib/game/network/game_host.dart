import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/board.dart';
import '../models/tile.dart';
import '../rules/tile_pool.dart';
import '../rules/word_validator.dart';
import 'multiplayer_models.dart';

class _PlayerSession {
  _PlayerSession({required this.name, this.socket});

  final String name;
  final Socket? socket;
  Board board = const Board();
  List<GameTile> availableTiles = [];
  int score = 0;
}

/// Runs a LAN Bananagrams match: accepts player connections, deals from a
/// single shared tile pool, and is the sole authority validating every move.
class GameHostServer extends ChangeNotifier implements MultiplayerController {
  GameHostServer({WordValidator? validator, Random? random})
      : _validator = validator ?? const WordValidator(words: {}),
        _random = random ?? Random();

  final WordValidator _validator;
  final Random _random;
  ServerSocket? _serverSocket;
  final List<_PlayerSession> _players = [];
  List<GameTile> _pool = [];
  MultiplayerPhase _phase = MultiplayerPhase.lobby;
  late _PlayerSession _host;

  bool get isStarted => _phase == MultiplayerPhase.playing;

  List<PlayerInfo> get roster => [
        for (final player in _players)
          PlayerInfo(
            name: player.name,
            score: player.score,
            tilesLeft: player.availableTiles.length,
          ),
      ];

  MultiplayerGameState get hostState => MultiplayerGameState(
        phase: _phase,
        board: _host.board,
        availableTiles: List.unmodifiable(_host.availableTiles),
        score: _host.score,
        poolCount: _pool.length,
        players: roster,
      );

  @override
  MultiplayerGameState get multiplayerState => hostState;

  Future<String> start(String hostName, {int port = 4224}) async {
    _host = _PlayerSession(name: hostName);
    _players.add(_host);
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _serverSocket!.listen(_handleConnection);
    notifyListeners();
    return '${await _localAddress()}:$port';
  }

  Future<String> _localAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        return address.address;
      }
    }
    return 'localhost';
  }

  void _handleConnection(Socket socket) {
    utf8.decoder
        .bind(socket)
        .transform(const LineSplitter())
        .listen(
          (line) => _handleLine(socket, line),
          onDone: () => _handleDisconnect(socket),
          onError: (_) => _handleDisconnect(socket),
          cancelOnError: true,
        );
  }

  void _handleDisconnect(Socket socket) {
    final removed = _players.any((player) => player.socket == socket);
    _players.removeWhere((player) => player.socket == socket);
    if (removed) {
      _broadcastRoster();
      notifyListeners();
    }
  }

  void _handleLine(Socket socket, String line) {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    if (message['t'] == 'join') {
      _handleJoin(socket, message);
      return;
    }

    _PlayerSession? session;
    for (final player in _players) {
      if (player.socket == socket) {
        session = player;
        break;
      }
    }
    if (session == null) {
      return;
    }

    switch (message['t']) {
      case 'place':
        _placeTile(
          session,
          message['tileId'] as String,
          BoardPosition(message['row'] as int, message['col'] as int),
        );
        break;
      case 'remove':
        _removeTile(
          session,
          BoardPosition(message['row'] as int, message['col'] as int),
        );
        break;
      case 'throw':
        _throwTile(session, message['tileId'] as String);
        break;
      case 'peel':
        _peel(session);
        break;
    }
  }

  void _handleJoin(Socket socket, Map<String, dynamic> message) {
    if (_phase == MultiplayerPhase.playing) {
      _sendError(socket, 'Game has already started');
      socket.destroy();
      return;
    }
    final name = (message['name'] as String?)?.trim();
    final nameTaken = name == null ||
        name.isEmpty ||
        _players.any((player) => player.name == name);
    if (nameTaken) {
      _sendError(socket, 'That name is taken or invalid');
      socket.destroy();
      return;
    }

    _players.add(_PlayerSession(name: name, socket: socket));
    _broadcastRoster();
    notifyListeners();
  }

  void startGame() {
    if (_phase == MultiplayerPhase.playing || _players.length < 2) {
      return;
    }
    _pool = createTilePool()..shuffle(_random);
    final handSize = startingHandSizeFor(_players.length);
    for (final player in _players) {
      final count = min(handSize, _pool.length);
      player.availableTiles = _pool.take(count).toList();
      _pool = _pool.skip(count).toList();
      player.board = const Board();
      player.score = 0;
    }
    _phase = MultiplayerPhase.playing;

    for (final player in _players) {
      _sendState(player);
    }
    _broadcastRoster();
    notifyListeners();
  }

  @override
  void placeTile(String tileId, BoardPosition position) =>
      _placeTile(_host, tileId, position);

  @override
  void removeTile(BoardPosition position) => _removeTile(_host, position);

  @override
  void throwTile(String tileId) => _throwTile(_host, tileId);

  @override
  void peel() => _peel(_host);

  void _placeTile(
    _PlayerSession player,
    String tileId,
    BoardPosition position,
  ) {
    final index = player.availableTiles.indexWhere((t) => t.id == tileId);
    if (index == -1 || player.board.isOccupied(position)) {
      return;
    }
    final tile = player.availableTiles[index];
    player.availableTiles = [...player.availableTiles]..removeAt(index);
    player.board = player.board.placeTile(position, tile);
    player.score = _validator.calculateScore(player.board);
    _sendState(player);
    _broadcastRoster();
    notifyListeners();
  }

  void _removeTile(_PlayerSession player, BoardPosition position) {
    final tile = player.board.tiles[position];
    if (tile == null) {
      return;
    }
    player.board = player.board.removeTile(position);
    player.availableTiles = [...player.availableTiles, tile];
    player.score = _validator.calculateScore(player.board);
    _sendState(player);
    _broadcastRoster();
    notifyListeners();
  }

  void _throwTile(_PlayerSession player, String tileId) {
    final index = player.availableTiles.indexWhere((t) => t.id == tileId);
    if (index == -1 || _pool.isEmpty) {
      return;
    }
    final thrown = player.availableTiles[index];
    final nextAvailable = [...player.availableTiles]..removeAt(index);
    final pool = [..._pool, thrown]..shuffle(_random);
    final drawCount = min(3, pool.length);
    player.availableTiles = [...nextAvailable, ...pool.take(drawCount)];
    _pool = pool.skip(drawCount).toList();
    _sendState(player);
    _broadcastRoster();
    notifyListeners();
  }

  // Classic Bananagrams "peel": the caller's rack must be empty and valid,
  // then every player (including the caller) draws one fresh tile.
  void _peel(_PlayerSession player) {
    if (player.availableTiles.isNotEmpty) {
      return;
    }
    final validation = _validator.validate(player.board);
    if (!validation.isValid) {
      _sendState(
        player,
        validationError: 'Invalid words: ${validation.invalidWords.join(', ')}',
      );
      return;
    }
    if (_pool.length < _players.length) {
      _sendState(player, validationError: 'Not enough tiles left to peel');
      return;
    }

    for (final other in _players) {
      final drawn = _pool.removeAt(0);
      other.availableTiles = [...other.availableTiles, drawn];
    }
    for (final other in _players) {
      _sendState(other);
    }
    _broadcastRoster();
    notifyListeners();
  }

  void _sendState(_PlayerSession player, {String? validationError}) {
    if (player.socket == null) {
      return;
    }
    final json = {
      't': 'state',
      'phase': _phase.name,
      'board': player.board.toJson(),
      'available': [for (final tile in player.availableTiles) tile.toJson()],
      'score': player.score,
      'poolCount': _pool.length,
      if (validationError != null) 'validationError': validationError,
    };
    player.socket!.writeln(jsonEncode(json));
  }

  void _sendError(Socket socket, String message) {
    socket.writeln(jsonEncode({'t': 'error', 'message': message}));
  }

  void _broadcastRoster() {
    final json = jsonEncode({
      't': 'roster',
      'phase': _phase.name,
      'poolCount': _pool.length,
      'players': [for (final info in roster) info.toJson()],
    });
    for (final player in _players) {
      player.socket?.writeln(json);
    }
  }

  Future<void> stop() async {
    for (final player in _players) {
      await player.socket?.close();
    }
    _players.clear();
    await _serverSocket?.close();
    _serverSocket = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
