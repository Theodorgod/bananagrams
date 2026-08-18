import 'package:flutter/material.dart';

import 'screens/game_page.dart';
import 'screens/home_page.dart';
import 'screens/multiplayer_lobby_page.dart';
import 'screens/settings_page.dart';
import 'screens/stats_page.dart';
import 'game/rules/bring_lexicon_loader.dart';
import 'game/rules/word_validator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final words = await const BringLexiconLoader().load();
  runApp(MyApp(wordValidator: WordValidator(words: words)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.wordValidator = const WordValidator(words: {})});

  final WordValidator wordValidator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bananagrams',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4C430),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF8E7),
          foregroundColor: Color(0xFF25231F),
          elevation: 0,
        ),
      ),
      initialRoute: HomePage.routeName,
      routes: {
        HomePage.routeName: (_) => const HomePage(),
        GamePage.routeName: (_) => GamePage(wordValidator: wordValidator),
        MultiplayerLobbyPage.routeName: (_) =>
            MultiplayerLobbyPage(wordValidator: wordValidator),
        StatsPage.routeName: (_) => const StatsPage(),
        SettingsPage.routeName: (_) => const SettingsPage(),
      },
    );
  }
}
