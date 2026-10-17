class TasbeehItem {
  final int id;
  final String text;
  final int targetCount;
  final String? fadl;
  final bool isCustom;

  const TasbeehItem({
    required this.id,
    required this.text,
    this.targetCount = 33,
    this.fadl,
    this.isCustom = false,
  });
}
