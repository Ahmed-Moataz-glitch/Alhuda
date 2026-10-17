import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_kit/audio.dart';
import 'package:quran_kit/core.dart';

/// Central audio service for Quran playback in Alhuda app.
/// Extends quran_kit reciters with iconic Egyptian reciters:
/// - Sheikh Mohammad Mahmoud Al-Tablaway (محمد محمود الطبلاوي)
/// - Sheikh Mustafa Ismail (مصطفى إسماعيل)
/// - Sheikh Mohamed Rifaat (محمد رفعت)
class AlhudaQuranAudioService {
  AlhudaQuranAudioService._();
  static final AlhudaQuranAudioService instance = AlhudaQuranAudioService._();

  static const String _baseUrl = 'https://everyayah.com/data/';
  static const String _rifaatBaseUrl =
      'https://cdn.mp3quran.net/audio/muhammad-refaat/r1/';

  /// Surahs available in historical recordings of Sheikh Mohamed Rifaat
  static const Set<int> kRifaatSurahs = {
    1, 10, 11, 12, 17, 18, 19, 20, 48, 54, 55, 56, 69, 72, 73,
    75, 76, 77, 78, 79, 81, 82, 83, 85, 86, 87, 88, 89, 96, 98, 100,
  };

  /// Complete list of reciters
  static const List<QuranReciter> reciters = [
    QuranReciter(
      index: 0,
      nameAr: 'مشاري العفاسي',
      nameEn: 'Mishary Alafasy',
      path: 'Alafasy_128kbps',
      qualityPaths: {
        AudioQuality.low: 'Alafasy_64kbps',
        AudioQuality.medium: 'Alafasy_128kbps',
      },
    ),
    QuranReciter(
      index: 1,
      nameAr: 'عبد الباسط عبد الصمد (مرتل)',
      nameEn: 'Abdul Basit (Murattal)',
      path: 'Abdul_Basit_Murattal_192kbps',
      qualityPaths: {
        AudioQuality.low: 'Abdul_Basit_Murattal_64kbps',
        AudioQuality.high: 'Abdul_Basit_Murattal_192kbps',
      },
    ),
    QuranReciter(
      index: 2,
      nameAr: 'عبد الباسط عبد الصمد (مجود)',
      nameEn: 'Abdul Basit (Mujawwad)',
      path: 'Abdul_Basit_Mujawwad_128kbps',
      qualityPaths: {AudioQuality.medium: 'Abdul_Basit_Mujawwad_128kbps'},
    ),
    QuranReciter(
      index: 3,
      nameAr: 'محمود خليل الحصري',
      nameEn: 'Mahmoud Khalil Al-Husary',
      path: 'Husary_128kbps',
      qualityPaths: {
        AudioQuality.medium: 'Husary_128kbps',
        AudioQuality.low: 'Husary_64kbps',
      },
    ),
    QuranReciter(
      index: 4,
      nameAr: 'محمود خليل الحصري (معلم)',
      nameEn: 'Husary (Muallim)',
      path: 'Husary_Muallim_128kbps',
      qualityPaths: {AudioQuality.medium: 'Husary_Muallim_128kbps'},
    ),
    QuranReciter(
      index: 5,
      nameAr: 'ماهر المعيقلي',
      nameEn: 'Maher Al-Muaiqly',
      path: 'MauroAl_Muaiqly128kbps',
      qualityPaths: {AudioQuality.medium: 'MauroAl_Muaiqly128kbps'},
    ),
    QuranReciter(
      index: 6,
      nameAr: 'سعود الشريم',
      nameEn: 'Saud Al-Shuraym',
      path: 'Shuraym_128kbps',
      qualityPaths: {AudioQuality.medium: 'Shuraym_128kbps'},
    ),
    QuranReciter(
      index: 7,
      nameAr: 'عبد الرحمن السديس',
      nameEn: 'Abdurrahman As-Sudais',
      path: 'Abdurrahmaan_As-Sudais_192kbps',
      qualityPaths: {
        AudioQuality.low: 'Abdurrahmaan_As-Sudais_64kbps',
        AudioQuality.high: 'Abdurrahmaan_As-Sudais_192kbps',
      },
    ),
    QuranReciter(
      index: 8,
      nameAr: 'محمد صديق المنشاوي',
      nameEn: 'Muhammad Siddiq Al-Minshawi',
      path: 'Minshawy_Murattal_128kbps',
      qualityPaths: {AudioQuality.medium: 'Minshawy_Murattal_128kbps'},
    ),
    QuranReciter(
      index: 9,
      nameAr: 'المنشاوي (مجود)',
      nameEn: 'Minshawi (Mujawwad)',
      path: 'Minshawy_Mujawwad_192kbps',
      qualityPaths: {AudioQuality.high: 'Minshawy_Mujawwad_192kbps'},
    ),
    QuranReciter(
      index: 10,
      nameAr: 'أحمد العجمي',
      nameEn: 'Ahmed Al-Ajmy',
      path: 'ahmed_ibn_ali_al_ajamy_128kbps',
      qualityPaths: {AudioQuality.medium: 'ahmed_ibn_ali_al_ajamy_128kbps'},
    ),
    QuranReciter(
      index: 11,
      nameAr: 'بندر بليلة',
      nameEn: 'Bandar Baleela',
      path: 'Bandar_Balila_128kbps',
      qualityPaths: {AudioQuality.medium: 'Bandar_Balila_128kbps'},
    ),
    QuranReciter(
      index: 12,
      nameAr: 'هاني الرفاعي',
      nameEn: 'Hani Ar-Rifai',
      path: 'Hani_Rifai_192kbps',
      qualityPaths: {AudioQuality.high: 'Hani_Rifai_192kbps'},
    ),
    QuranReciter(
      index: 13,
      nameAr: 'ياسر الدوسري',
      nameEn: 'Yasser Al-Dosari',
      path: 'Yasser_Ad-Dussary_128kbps',
      qualityPaths: {AudioQuality.medium: 'Yasser_Ad-Dussary_128kbps'},
    ),
    QuranReciter(
      index: 14,
      nameAr: 'ناصر القطامي',
      nameEn: 'Nasser Al-Qatami',
      path: 'Nasser_Alqatami_128kbps',
      qualityPaths: {AudioQuality.medium: 'Nasser_Alqatami_128kbps'},
    ),
    QuranReciter(
      index: 15,
      nameAr: 'فارس عباد',
      nameEn: 'Fares Abbad',
      path: 'Fares_Abbad_64kbps',
      qualityPaths: {AudioQuality.low: 'Fares_Abbad_64kbps'},
    ),
    QuranReciter(
      index: 16,
      nameAr: 'عبد الله بصفر',
      nameEn: 'Abdullah Basfar',
      path: 'Basfar_192kbps',
      qualityPaths: {AudioQuality.high: 'Basfar_192kbps'},
    ),
    QuranReciter(
      index: 17,
      nameAr: 'إبراهيم الأخضر',
      nameEn: 'Ibrahim Al-Akhdar',
      path: 'Ibrahim_Akhdar_32kbps',
      qualityPaths: {AudioQuality.low: 'Ibrahim_Akhdar_32kbps'},
    ),
    QuranReciter(
      index: 18,
      nameAr: 'محمد أيوب',
      nameEn: 'Muhammad Ayyoub',
      path: 'Muhammad_Ayyoub_128kbps',
      qualityPaths: {AudioQuality.medium: 'Muhammad_Ayyoub_128kbps'},
    ),
    QuranReciter(
      index: 19,
      nameAr: 'علي الحذيفي',
      nameEn: 'Ali Al-Hudhaify',
      path: 'Hudhaify_128kbps',
      qualityPaths: {AudioQuality.medium: 'Hudhaify_128kbps'},
    ),
    QuranReciter(
      index: 20,
      nameAr: 'صلاح بو خاطر',
      nameEn: 'Salah Bukhatir',
      path: 'Salaah_AbdulRahman_Bukhatir_128kbps',
      qualityPaths: {AudioQuality.medium: 'Salaah_AbdulRahman_Bukhatir_128kbps'},
    ),
    QuranReciter(
      index: 21,
      nameAr: 'عبد الله المطرود',
      nameEn: 'Abdullah Al-Matroud',
      path: 'Abdullah_Matroud_128kbps',
      qualityPaths: {AudioQuality.medium: 'Abdullah_Matroud_128kbps'},
    ),
    // New iconic Egyptian Reciters added upon user request:
    QuranReciter(
      index: 22,
      nameAr: 'محمد محمود الطبلاوي',
      nameEn: 'Mohammad Al-Tablaway',
      path: 'Mohammad_al_Tablaway_128kbps',
      qualityPaths: {
        AudioQuality.low: 'Mohammad_al_Tablaway_64kbps',
        AudioQuality.medium: 'Mohammad_al_Tablaway_128kbps',
      },
    ),
    QuranReciter(
      index: 23,
      nameAr: 'مصطفى إسماعيل',
      nameEn: 'Mustafa Ismail',
      path: 'Mustafa_Ismail_48kbps',
      qualityPaths: {
        AudioQuality.low: 'Mustafa_Ismail_48kbps',
        AudioQuality.medium: 'Mustafa_Ismail_48kbps',
      },
    ),
    QuranReciter(
      index: 24,
      nameAr: 'محمد رفعت (قيثارة السماء)',
      nameEn: 'Mohamed Rifaat',
      path: 'muhammad-refaat',
      qualityPaths: {
        AudioQuality.medium: 'muhammad-refaat',
      },
    ),
  ];

  AudioPlayer? _player;
  final ValueNotifier<QuranAudioState> state =
      ValueNotifier(const QuranAudioState());

  QuranStorage storage = JsonFileQuranStorage.instance;

  int _reciterIndex = 0;
  int get reciterIndex => _reciterIndex;

  AudioQuality _quality = AudioQuality.medium;
  AudioQuality get quality => _quality;

  double _speed = 1.0;
  double get speed => _speed;

  int _repeatCount = 0;
  int _currentRepeat = 0;

  Future<void> init() async {
    _player ??= AudioPlayer();
    final saved = await storage.getInt('quran_audio_reciter');
    if (saved != null && saved >= 0 && saved < reciters.length) {
      _reciterIndex = saved;
    }
    final savedQuality = await storage.getString('quran_audio_quality');
    if (savedQuality != null) {
      _quality = AudioQuality.values.firstWhere(
        (q) => q.key == savedQuality,
        orElse: () => AudioQuality.medium,
      );
    }

    _player!.playerStateStream.listen((s) {
      state.value = state.value.copyWith(
        isPlaying: s.playing,
        isLoading: s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering,
      );

      if (s.processingState == ProcessingState.completed) {
        _autoAdvance();
      }
    });

    _player!.positionStream.listen((pos) {
      state.value = state.value.copyWith(position: pos);
    });

    _player!.durationStream.listen((dur) {
      if (dur != null) {
        state.value = state.value.copyWith(duration: dur);
      }
    });
  }

  /// Play a specific ayah
  Future<void> playAyah(int surah, int ayah) async {
    _player ??= AudioPlayer();
    final s3 = surah.toString().padLeft(3, '0');
    final a3 = ayah.toString().padLeft(3, '0');
    final reciter = reciters[_reciterIndex];

    state.value = state.value.copyWith(
      surah: surah,
      ayah: ayah,
      isActive: true,
      isLoading: true,
      reciterIndex: _reciterIndex,
    );

    try {
      if (reciter.path == 'muhammad-refaat') {
        // Mohamed Rifaat playback
        if (kRifaatSurahs.contains(surah)) {
          final localFile = await _localAudioFile('muhammad-refaat', '$s3.mp3');
          if (localFile.existsSync()) {
            await _player!.setFilePath(localFile.path);
          } else {
            final url = '$_rifaatBaseUrl$s3.mp3';
            await _player!.setUrl(url);
          }
        } else {
          // Graceful fallback to Minshawi Murattal for unrecorded surahs
          final cdnPath = 'Minshawy_Murattal_128kbps';
          final fileName = '$s3$a3.mp3';
          final localFile = await _localAudioFile(cdnPath, fileName);
          if (localFile.existsSync()) {
            await _player!.setFilePath(localFile.path);
          } else {
            final url = '$_baseUrl$cdnPath/$fileName';
            await _player!.setUrl(url);
          }
        }
      } else {
        // Standard EveryAyah reciters (including Tablawi and Mustafa Ismail)
        final cdnPath = reciter.pathForQuality(_quality);
        final fileName = '$s3$a3.mp3';

        final localFile = await _localAudioFile(cdnPath, fileName);
        if (localFile.existsSync()) {
          await _player!.setFilePath(localFile.path);
        } else {
          final url = '$_baseUrl$cdnPath/$fileName';
          await _player!.setUrl(url);
        }
      }
      _player!.play();
    } catch (e) {
      debugPrint('Error playing ayah audio: $e');
      state.value = state.value.copyWith(isLoading: false, isPlaying: false);
    }
  }

  void togglePlayPause() {
    if (_player == null) return;
    if (_player!.playing) {
      _player!.pause();
    } else {
      _player!.play();
    }
  }

  void stop() {
    _player?.stop();
    state.value = const QuranAudioState();
  }

  void skipNext() {
    final s = state.value;
    final meta = QuranMetadata.instance;
    final surahInfo = meta.surahByNumber(s.surah);
    if (surahInfo == null) return;

    if (s.ayah < surahInfo.ayahCount) {
      playAyah(s.surah, s.ayah + 1);
    } else if (s.surah < 114) {
      playAyah(s.surah + 1, 1);
    }
  }

  void skipPrevious() {
    final s = state.value;
    if (s.ayah > 1) {
      playAyah(s.surah, s.ayah - 1);
    } else if (s.surah > 1) {
      final meta = QuranMetadata.instance;
      final prevSurah = meta.surahByNumber(s.surah - 1);
      if (prevSurah != null) {
        playAyah(s.surah - 1, prevSurah.ayahCount);
      }
    }
  }

  Future<void> setReciter(int index) async {
    if (index < 0 || index >= reciters.length) return;
    _reciterIndex = index;
    await storage.setInt('quran_audio_reciter', index);
    state.value = state.value.copyWith(reciterIndex: index);

    if (state.value.isActive) {
      playAyah(state.value.surah, state.value.ayah);
    }
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _player?.setSpeed(_speed);
  }

  void setRepeatCount(int count) {
    _repeatCount = count;
    _currentRepeat = 0;
  }

  Future<void> playSurahFrom(int surah, int startAyah) async {
    await playAyah(surah, startAyah);
  }

  void _autoAdvance() {
    if (_repeatCount != 0) {
      if (_repeatCount == -1) {
        playAyah(state.value.surah, state.value.ayah);
        return;
      }
      _currentRepeat++;
      if (_currentRepeat < _repeatCount) {
        playAyah(state.value.surah, state.value.ayah);
        return;
      }
      _currentRepeat = 0;
    }

    final s = state.value;
    final meta = QuranMetadata.instance;
    final surahInfo = meta.surahByNumber(s.surah);
    if (surahInfo == null) return;

    if (s.ayah < surahInfo.ayahCount) {
      playAyah(s.surah, s.ayah + 1);
    } else if (s.surah < 114) {
      playAyah(s.surah + 1, 1);
    } else {
      stop();
    }
  }

  Future<void> setQuality(AudioQuality q) async {
    _quality = q;
    await storage.setString('quran_audio_quality', q.key);
  }

  Directory? _audioDir;

  Future<Directory> _getAudioDir() async {
    if (_audioDir != null) return _audioDir!;
    final appSupport = await getApplicationSupportDirectory();
    _audioDir = Directory('${appSupport.path}/quran_audio');
    if (!_audioDir!.existsSync()) {
      await _audioDir!.create(recursive: true);
    }
    return _audioDir!;
  }

  Future<File> _localAudioFile(String reciterPath, String fileName) async {
    final dir = await _getAudioDir();
    final reciterDir = Directory('${dir.path}/$reciterPath');
    if (!reciterDir.existsSync()) {
      await reciterDir.create(recursive: true);
    }
    return File('${reciterDir.path}/$fileName');
  }

  final ValueNotifier<double?> downloadProgress = ValueNotifier(null);

  Future<void> downloadSurah(int surah, {int? reciterIndex}) async {
    final meta = QuranMetadata.instance;
    final surahInfo = meta.surahByNumber(surah);
    if (surahInfo == null) return;

    final idx = reciterIndex ?? _reciterIndex;
    final reciter = reciters[idx];
    downloadProgress.value = 0.0;

    final client = HttpClient();
    try {
      if (reciter.path == 'muhammad-refaat') {
        if (!kRifaatSurahs.contains(surah)) return;
        final s3 = surah.toString().padLeft(3, '0');
        final localFile = await _localAudioFile('muhammad-refaat', '$s3.mp3');
        if (!localFile.existsSync()) {
          final url = '$_rifaatBaseUrl$s3.mp3';
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();
          if (response.statusCode == 200) {
            final bytes = await response.fold<List<int>>(
              <int>[],
              (prev, chunk) => prev..addAll(chunk),
            );
            await localFile.writeAsBytes(bytes, flush: true);
          }
        }
        downloadProgress.value = 1.0;
        return;
      }

      final cdnPath = reciter.pathForQuality(_quality);
      final total = surahInfo.ayahCount;

      for (int a = 1; a <= total; a++) {
        final s3 = surah.toString().padLeft(3, '0');
        final a3 = a.toString().padLeft(3, '0');
        final fileName = '$s3$a3.mp3';
        final localFile = await _localAudioFile(cdnPath, fileName);

        if (!localFile.existsSync()) {
          final url = '$_baseUrl$cdnPath/$fileName';
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();
          if (response.statusCode == 200) {
            final bytes = await response.fold<List<int>>(
              <int>[],
              (prev, chunk) => prev..addAll(chunk),
            );
            await localFile.writeAsBytes(bytes, flush: true);
          }
        }
        downloadProgress.value = a / total;
      }
    } finally {
      client.close();
      downloadProgress.value = null;
    }
  }

  Future<void> downloadJuz(int juz, {int? reciterIndex}) async {
    final meta = QuranMetadata.instance;
    final startPage = meta.pageForJuz(juz);
    final endPage = juz < 30 ? meta.pageForJuz(juz + 1) - 1 : 604;

    final pairs = <({int surah, int ayah})>[];
    for (int s = 1; s <= 114; s++) {
      final info = meta.surahByNumber(s);
      if (info == null) continue;
      final surahStart = meta.pageForSurah(s);
      for (int a = 1; a <= info.ayahCount; a++) {
        if (surahStart >= startPage && surahStart <= endPage) {
          pairs.add((surah: s, ayah: a));
        }
      }
    }

    final idx = reciterIndex ?? _reciterIndex;
    final reciter = reciters[idx];
    final cdnPath = reciter.pathForQuality(_quality);
    final total = pairs.length;
    if (total == 0) return;
    downloadProgress.value = 0.0;

    final client = HttpClient();
    try {
      for (int i = 0; i < total; i++) {
        final p = pairs[i];
        final s3 = p.surah.toString().padLeft(3, '0');
        final a3 = p.ayah.toString().padLeft(3, '0');
        final fileName = '$s3$a3.mp3';
        final localFile = await _localAudioFile(cdnPath, fileName);

        if (!localFile.existsSync()) {
          final url = '$_baseUrl$cdnPath/$fileName';
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();
          if (response.statusCode == 200) {
            final bytes = await response.fold<List<int>>(
              <int>[],
              (prev, chunk) => prev..addAll(chunk),
            );
            await localFile.writeAsBytes(bytes, flush: true);
          }
        }
        downloadProgress.value = (i + 1) / total;
      }
    } finally {
      client.close();
      downloadProgress.value = null;
    }
  }

  Future<bool> isSurahDownloaded(int surah, {int? reciterIndex}) async {
    final meta = QuranMetadata.instance;
    final surahInfo = meta.surahByNumber(surah);
    if (surahInfo == null) return false;

    final idx = reciterIndex ?? _reciterIndex;
    final reciter = reciters[idx];

    if (reciter.path == 'muhammad-refaat') {
      if (!kRifaatSurahs.contains(surah)) return false;
      final s3 = surah.toString().padLeft(3, '0');
      final localFile = await _localAudioFile('muhammad-refaat', '$s3.mp3');
      return localFile.existsSync();
    }

    final cdnPath = reciter.pathForQuality(_quality);
    for (int a = 1; a <= surahInfo.ayahCount; a++) {
      final s3 = surah.toString().padLeft(3, '0');
      final a3 = a.toString().padLeft(3, '0');
      final localFile = await _localAudioFile(cdnPath, '$s3$a3.mp3');
      if (!localFile.existsSync()) return false;
    }
    return true;
  }

  Future<void> deleteSurahDownload(int surah, {int? reciterIndex}) async {
    final meta = QuranMetadata.instance;
    final surahInfo = meta.surahByNumber(surah);
    if (surahInfo == null) return;

    final idx = reciterIndex ?? _reciterIndex;
    final reciter = reciters[idx];

    if (reciter.path == 'muhammad-refaat') {
      final s3 = surah.toString().padLeft(3, '0');
      final localFile = await _localAudioFile('muhammad-refaat', '$s3.mp3');
      if (localFile.existsSync()) await localFile.delete();
      return;
    }

    final cdnPath = reciter.pathForQuality(_quality);
    for (int a = 1; a <= surahInfo.ayahCount; a++) {
      final s3 = surah.toString().padLeft(3, '0');
      final a3 = a.toString().padLeft(3, '0');
      final localFile = await _localAudioFile(cdnPath, '$s3$a3.mp3');
      if (localFile.existsSync()) await localFile.delete();
    }
  }

  Future<int> get offlineDiskUsage async {
    final dir = await _getAudioDir();
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> clearAllDownloads() async {
    final dir = await _getAudioDir();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
