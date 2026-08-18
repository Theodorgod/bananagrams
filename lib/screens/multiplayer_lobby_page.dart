import 'package:flutter/material.dart';

import '../game/network/game_client.dart';
import '../game/network/game_host.dart';
import '../game/network/multiplayer_models.dart';
import '../game/rules/word_validator.dart';
import 'multiplayer_game_page.dart';

enum _Mode { choose, host, join }

class MultiplayerLobbyPage extends StatefulWidget {
  const MultiplayerLobbyPage({
    super.key,
    this.wordValidator = const WordValidator(words: {}),
  });

  static const routeName = '/multiplayer';
  final WordValidator wordValidator;

  @override
  State<MultiplayerLobbyPage> createState() => _MultiplayerLobbyPageState();
}

class _MultiplayerLobbyPageState extends State<MultiplayerLobbyPage> {
  _Mode _mode = _Mode.choose;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  GameHostServer? _host;
  GameClientConnection? _client;
  String? _hostAddress;
  String? _error;
  bool _busy = false;
  bool _navigated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _host?.dispose();
    _client?.dispose();
    super.dispose();
  }

  Future<void> _startHosting() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name first');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final host = GameHostServer(validator: widget.wordValidator);
    try {
      final address = await host.start(name);
      setState(() {
        _host = host;
        _hostAddress = address;
        _mode = _Mode.host;
        _busy = false;
      });
      host.addListener(_onControllerChanged);
    } catch (error) {
      setState(() {
        _error = 'Could not start hosting: $error';
        _busy = false;
      });
    }
  }

  Future<void> _joinGame() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      setState(() => _error = 'Enter your name and the host address');
      return;
    }
    final parts = address.split(':');
    final host = parts.first;
    final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 4224 : 4224;

    setState(() {
      _busy = true;
      _error = null;
    });
    final client = GameClientConnection();
    final connected = await client.connect(host, port, name);
    if (!connected) {
      setState(() {
        _error = client.connectionError ?? 'Could not connect';
        _busy = false;
      });
      return;
    }
    setState(() {
      _client = client;
      _mode = _Mode.join;
      _busy = false;
    });
    client.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_navigated) {
      return;
    }
    final state = _host?.hostState ?? _client?.state;
    if (state == null) {
      return;
    }
    if (_client?.connectionError != null) {
      setState(() => _error = _client!.connectionError);
      return;
    }
    if (state.phase == MultiplayerPhase.playing) {
      _navigated = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MultiplayerGamePage(
            controller: (_host ?? _client!),
          ),
        ),
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host / Join Game')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (_mode) {
          _Mode.choose => _buildChoose(),
          _Mode.host => _buildHostLobby(),
          _Mode.join => _buildJoinLobby(),
        },
      ),
    );
  }

  Widget _buildChoose() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _startHosting,
            icon: const Icon(Icons.wifi_tethering_rounded),
            label: const Text('HOST GAME'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: "Host address",
              hintText: '192.168.1.5:4224',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _joinGame,
            icon: const Icon(Icons.login_rounded),
            label: const Text('JOIN GAME'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Widget _buildHostLobby() {
    final host = _host!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Share this address with other players:'),
          const SizedBox(height: 8),
          SelectableText(
            _hostAddress ?? '',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 24),
          Text('Players (${host.roster.length}):'),
          for (final player in host.roster) Text(player.name),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: host.roster.length >= 2 ? host.startGame : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('START GAME'),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinLobby() {
    final client = _client!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Waiting for the host to start the game...'),
          const SizedBox(height: 24),
          Text('Players (${client.state.players.length}):'),
          for (final player in client.state.players) Text(player.name),
        ],
      ),
    );
  }
}
