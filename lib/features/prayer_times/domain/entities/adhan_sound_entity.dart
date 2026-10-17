enum AdhanAudioSourceType {
  asset,
  url,
}

class AdhanSound {
  final String id;
  final String title;
  final String muadhin;
  final String source;
  final AdhanAudioSourceType sourceType;
  final String durationText;

  const AdhanSound({
    required this.id,
    required this.title,
    required this.muadhin,
    required this.source,
    this.sourceType = AdhanAudioSourceType.asset,
    this.durationText = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdhanSound && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

abstract class AdhanData {
  static const AdhanSound defaultAdhan = AdhanSound(
    id: 'qatami',
    title: 'أذان ناصر القطامي',
    muadhin: 'الشيخ ناصر القطامي',
    source: 'assets/audio/nasser_al_qatami.mp3',
    sourceType: AdhanAudioSourceType.asset,
    durationText: '02:12',
  );

  static const List<AdhanSound> availableSounds = [
    AdhanSound(
      id: 'rifaat',
      title: 'أذان الشيخ محمد رفعت (قيثارة السماء)',
      muadhin: 'الشيخ محمد رفعت',
      source: 'assets/audio/mohamed_rifaat.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:23',
    ),
    AdhanSound(
      id: 'mostafa_ismail',
      title: 'أذان الشيخ مصطفى إسماعيل',
      muadhin: 'الشيخ مصطفى إسماعيل',
      source: 'assets/audio/mostafa_ismail.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:03',
    ),
    AdhanSound(
      id: 'abdulbasit',
      title: 'أذان الشيخ عبد الباسط عبد الصمد',
      muadhin: 'الشيخ عبد الباسط عبد الصمد',
      source: 'assets/audio/abdulbasit_abdulsamad.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:20',
    ),
    AdhanSound(
      id: 'minshawi',
      title: 'أذان الشيخ محمد صديق المنشاوي',
      muadhin: 'الشيخ محمد صديق المنشاوي',
      source: 'assets/audio/mohamed_siddiq_elminshawi.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:53',
    ),
    AdhanSound(
      id: 'shuaisha',
      title: 'أذان الشيخ أبو العينين شعيشع',
      muadhin: 'الشيخ أبو العينين شعيشع',
      source: 'assets/audio/abul_aynayn_shuaisha.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:56',
    ),
    AdhanSound(
      id: 'hussary',
      title: 'أذان الشيخ محمود خليل الحصري',
      muadhin: 'الشيخ محمود خليل الحصري',
      source: 'assets/audio/mahmoud_khalil_alhussary.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '02:07',
    ),
    AdhanSound(
      id: 'mahmoud_ramadan',
      title: 'أذان الشيخ محمود محمد رمضان (مقام البيات)',
      muadhin: 'الشيخ محمود محمد رمضان',
      source: 'assets/audio/mahmoud_mohamed_ramadan.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:48',
    ),
    AdhanSound(
      id: 'banna',
      title: 'أذان الشيخ محمد علي البنا',
      muadhin: 'الشيخ محمد علي البنا',
      source: 'assets/audio/mohamed_ali_elbanna.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '02:46',
    ),
    AdhanSound(
      id: 'qatami',
      title: 'أذان ناصر القطامي',
      muadhin: 'الشيخ ناصر القطامي',
      source: 'assets/audio/nasser_al_qatami.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '02:12',
    ),
    AdhanSound(
      id: 'makkah',
      title: 'أذان الحرم المكي (علي ملا)',
      muadhin: 'الشيخ علي أحمد ملا',
      source: 'assets/audio/makkah_ali_mullah.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:51',
    ),
    AdhanSound(
      id: 'madinah',
      title: 'أذان المسجد النبوي الشريف',
      muadhin: 'مؤذنو الحرم النبوي بالمدينة',
      source: 'assets/audio/madinah.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '01:35',
    ),
    AdhanSound(
      id: 'alafasy',
      title: 'أذان مشاري راشد العفاسي',
      muadhin: 'الشيخ مشاري راشد العفاسي',
      source: 'assets/audio/mishary_alafasy.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '04:22',
    ),
    AdhanSound(
      id: 'basnawi',
      title: 'أذان الحرم المكي (أحمد بصنوي)',
      muadhin: 'الشيخ أحمد بصنوي',
      source: 'assets/audio/ahmed_basnawi.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '02:47',
    ),
    AdhanSound(
      id: 'essam_khan',
      title: 'أذان الحرم المكي (عصام خان)',
      muadhin: 'الشيخ عصام خان',
      source: 'assets/audio/essam_khan.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '04:06',
    ),
    AdhanSound(
      id: 'ahmad_khoja',
      title: 'أذان الحرم المكي (أحمد خوجة)',
      muadhin: 'الشيخ أحمد خوجة',
      source: 'assets/audio/ahmad_khoja.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '03:18',
    ),
    AdhanSound(
      id: 'dubai',
      title: 'أذان مساجد دبي',
      muadhin: 'مؤذنو مساجد دبي',
      source: 'assets/audio/dubai.mp3',
      sourceType: AdhanAudioSourceType.asset,
      durationText: '02:55',
    ),
  ];
}
