class TasbeehItem {
  final int id;
  final String text;
  final int targetCount;

  const TasbeehItem({
    required this.id,
    required this.text,
    this.targetCount = 33,
  });
}
