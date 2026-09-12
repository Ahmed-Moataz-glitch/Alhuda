/// نموذج طبعة المصحف الشريف
class MushafEdition {
  final String id;
  final String name;
  final String shortName;
  final String riwayah;
  final String publisher;
  final String approximateSize;
  final double approximateSizeMB;
  final int totalPages;
  final String folderName;
  final String baseUrl;
  final String? fallbackBaseUrl;
  final bool cropPublisherBorders;
  final bool hasTajweedColors;

  const MushafEdition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.riwayah,
    required this.publisher,
    required this.approximateSize,
    required this.approximateSizeMB,
    this.totalPages = 604,
    required this.folderName,
    required this.baseUrl,
    this.fallbackBaseUrl,
    required this.cropPublisherBorders,
    required this.hasTajweedColors,
  });

  /// الطبعات المتوفرة في التطبيق
  static const MushafEdition hafsTajweed = MushafEdition(
    id: 'hafs_tajweed',
    name: 'مصحف التجويد الملون',
    shortName: 'مصحف التجويد',
    riwayah: 'حفص عن عاصم',
    publisher: 'دار المعرفة',
    approximateSize: '85 ميجابايت',
    approximateSizeMB: 85.0,
    totalPages: 604,
    folderName: 'quran_tajweed_pages',
    baseUrl:
        'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/easyquran.com/hafs-tajweed',
    fallbackBaseUrl:
        'https://cdn.jsdelivr.net/gh/QuranHub/quran-pages-images@main/easyquran.com/hafs-tajweed',
    cropPublisherBorders: true,
    hasTajweedColors: true,
  );

  static const MushafEdition madinahHafs = MushafEdition(
    id: 'madinah_hafs',
    name: 'مصحف المدينة المنورة',
    shortName: 'مصحف المدينة',
    riwayah: 'حفص عن عاصم',
    publisher: 'مجمع الملك فهد',
    approximateSize: '180 ميجابايت',
    approximateSizeMB: 180.0,
    totalPages: 604,
    folderName: 'quran_madinah_hafs_pages',
    baseUrl:
        'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/kfgqpc/hafs-wasat',
    fallbackBaseUrl:
        'https://cdn.jsdelivr.net/gh/QuranHub/quran-pages-images@main/kfgqpc/hafs-wasat',
    cropPublisherBorders: false,
    hasTajweedColors: false,
  );

  static const MushafEdition madinahWarsh = MushafEdition(
    id: 'madinah_warsh',
    name: 'مصحف المدينة (ورش)',
    shortName: 'مصحف ورش',
    riwayah: 'ورش عن نافع',
    publisher: 'مجمع الملك فهد',
    approximateSize: '180 ميجابايت',
    approximateSizeMB: 180.0,
    totalPages: 604,
    folderName: 'quran_madinah_warsh_pages',
    baseUrl:
        'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/kfgqpc/warsh',
    fallbackBaseUrl:
        'https://cdn.jsdelivr.net/gh/QuranHub/quran-pages-images@main/kfgqpc/warsh',
    cropPublisherBorders: false,
    hasTajweedColors: false,
  );

  static const MushafEdition madinahShubah = MushafEdition(
    id: 'madinah_shubah',
    name: 'مصحف المدينة (شعبة)',
    shortName: 'مصحف شعبة',
    riwayah: 'شعبة عن عاصم',
    publisher: 'مجمع الملك فهد',
    approximateSize: '180 ميجابايت',
    approximateSizeMB: 180.0,
    totalPages: 604,
    folderName: 'quran_madinah_shubah_pages',
    baseUrl:
        'https://raw.githubusercontent.com/Zohanur2026/zohanur-mushaf-pages-shubah/main',
    fallbackBaseUrl:
        'https://cdn.jsdelivr.net/gh/Zohanur2026/zohanur-mushaf-pages-shubah@main',
    cropPublisherBorders: false,
    hasTajweedColors: false,
  );

  /// قائمة الطبعات المدعومة
  static const List<MushafEdition> availableEditions = [
    hafsTajweed,
    madinahHafs,
    madinahWarsh,
    madinahShubah,
  ];

  static MushafEdition fromId(String id) {
    return availableEditions.firstWhere(
      (e) => e.id == id,
      orElse: () => hafsTajweed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MushafEdition &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
