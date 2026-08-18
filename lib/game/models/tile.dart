class GameTile {
  const GameTile({
    required this.id,
    required this.letter,
  });

  final String id;
  final String letter;

  Map<String, dynamic> toJson() => {'id': id, 'letter': letter};

  factory GameTile.fromJson(Map<String, dynamic> json) {
    return GameTile(id: json['id'] as String, letter: json['letter'] as String);
  }
}
