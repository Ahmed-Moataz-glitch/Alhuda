import 'package:alhuda/features/tasbeeh/domain/entities/tasbeeh_item.dart';
import 'package:alhuda/features/tasbeeh/domain/repositories/tasbeeh_repository.dart';

class TasbeehRepositoryImpl implements TasbeehRepository {
  static const List<TasbeehItem> _defaults = [
    TasbeehItem(
      id: 1,
      text: 'سبحان الله وبحمده سبحان الله العظيم',
      targetCount: 100,
      fadl: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن',
    ),
    TasbeehItem(
      id: 2,
      text: 'لا حول ولا قوة إلا بالله',
      targetCount: 33,
      fadl: 'كنز من كنوز الجنة وباب من أبوابها',
    ),
    TasbeehItem(
      id: 3,
      text: 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر',
      targetCount: 33,
      fadl: 'أحب الكلام إلى الله وهن الباقيات الصالحات',
    ),
    TasbeehItem(
      id: 4,
      text: 'أستغفر الله وأتوب إليه',
      targetCount: 100,
      fadl: 'مغفرة الذنوب وتفريج الهموم وزيادة الرزق والقوة',
    ),
    TasbeehItem(
      id: 5,
      text: 'اللهم صلّ وسلم على نبينا محمد',
      targetCount: 10,
      fadl: 'من صلى عليّ صلاة صلى الله عليه بها عشراً',
    ),
    TasbeehItem(
      id: 6,
      text: 'سبحان الله',
      targetCount: 33,
      fadl: 'تسبيح الله وتنزيهه عن كل نقص',
    ),
    TasbeehItem(
      id: 7,
      text: 'الحمد لله',
      targetCount: 33,
      fadl: 'أفضل الدعاء الحمد لله، وتملأ الميزان',
    ),
    TasbeehItem(
      id: 8,
      text: 'لا إله إلا الله',
      targetCount: 33,
      fadl: 'أفضل الذكر لا إله إلا الله، كلمة التوحيد',
    ),
    TasbeehItem(
      id: 9,
      text: 'الله أكبر',
      targetCount: 33,
      fadl: 'تكبير الله وتعظيمه وإجلاله',
    ),
    TasbeehItem(
      id: 10,
      text: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير',
      targetCount: 100,
      fadl: 'عدل عتق عشر رقاب وحط مائة سيئة وحرز من الشيطان',
    ),
    TasbeehItem(
      id: 11,
      text: 'أستغفر الله العظيم الذي لا إله إلا هو الحي القيوم وأتوب إليه',
      targetCount: 33,
      fadl: 'غُفرت ذنوبه وإن كان فر من الزحف',
    ),
    TasbeehItem(
      id: 12,
      text: 'اللهم صل على محمد وعلى آل محمد كما صليت على إبراهيم وعلى آل إبراهيم إنك حميد مجيد',
      targetCount: 10,
      fadl: 'الصلاة الإبراهيمية المباركة التامة',
    ),
    TasbeehItem(
      id: 13,
      text: 'لا إله إلا أنت سبحانك إني كنت من الظالمين',
      targetCount: 33,
      fadl: 'دعوة ذي النون ما دعا بها مسلم في شيء قط إلا استجاب الله له',
    ),
    TasbeehItem(
      id: 14,
      text: 'سبحان الله وبحمده، عدد خلقه، ورضا نفسه، وزنة عرشه، ومداد كلماته',
      targetCount: 3,
      fadl: 'ذكر مضاعف الأجر يعدل ساعات طويلة من التسبيح',
    ),
    TasbeehItem(
      id: 15,
      text: 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم',
      targetCount: 7,
      fadl: 'من قالها سبعاً كفاه الله ما أهمه من أمر دنياه وآخرته',
    ),
    TasbeehItem(
      id: 16,
      text: 'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين',
      targetCount: 33,
      fadl: 'دعاء الاستغاثة برحمة الله وتفويض الأمور إليه',
    ),
    TasbeehItem(
      id: 17,
      text: 'حسبي الله ونعم الوكيل',
      targetCount: 33,
      fadl: 'أمان وتفويض الأمر لله عند المخاوف والشدائد',
    ),
    TasbeehItem(
      id: 18,
      text: 'توكلت على الله، لا حول ولا قوة إلا بالله',
      targetCount: 33,
      fadl: 'يقال لك: هُديت وكُفيت ووُقيت وتنحى عنك الشيطان',
    ),
    TasbeehItem(
      id: 19,
      text: 'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً ورسولاً',
      targetCount: 3,
      fadl: 'كان حقاً على الله أن يرضيه يوم القيامة',
    ),
    TasbeehItem(
      id: 20,
      text: 'اللهم إني أسألك العفو والعافية في الدنيا والآخرة',
      targetCount: 33,
      fadl: 'سؤال العافية والسلامة في الدين والدنيا والأهل والمال',
    ),
    TasbeehItem(
      id: 21,
      text: 'اللهم أنت ربي لا إله إلا أنت، خلقتني وأنا عبدك، وأنا على عهدك ووعدك ما استطعت، أعوذ بك من شر ما صنعت، أبوء لك بنعمتك علي، وأبوء بذنبي فاغفر لي فإنه لا يغفر الذنوب إلا أنت',
      targetCount: 1,
      fadl: 'سيد الاستغفار: من قاله موقناً به فمات دخل الجنة',
    ),
    TasbeehItem(
      id: 22,
      text: 'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم',
      targetCount: 3,
      fadl: 'حفظ وسلامة من كل ضرر وفجأة بلاء',
    ),
    TasbeehItem(
      id: 23,
      text: 'أعوذ بكلمات الله التامات من شر ما خلق',
      targetCount: 3,
      fadl: 'حفظ وتحصين تام من الشرور والهوام',
    ),
    TasbeehItem(
      id: 24,
      text: 'اللهم إنك عفو تحب العفو فاعف عني',
      targetCount: 33,
      fadl: 'دعاء العفو الجامع الذي أوصى به النبي ﷺ',
    ),
    TasbeehItem(
      id: 25,
      text: 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
      targetCount: 33,
      fadl: 'أكثر وأجمع دعاء للنبي صلى الله عليه وسلم',
    ),
    TasbeehItem(
      id: 26,
      text: 'يا مقلب القلوب ثبت قلبي على دينك',
      targetCount: 33,
      fadl: 'دعاء الثبات على الإيمان والهدى',
    ),
    TasbeehItem(
      id: 27,
      text: 'اللهم أعني على ذكرك وشكرك وحسن عبادتك',
      targetCount: 33,
      fadl: 'وصية النبي ﷺ لمعاذ دبر كل صلاة مكتوبة',
    ),
    TasbeehItem(
      id: 28,
      text: 'رب اغفر لي وارحمني واهدني وعافني وارزقني',
      targetCount: 33,
      fadl: 'الدعاء المأثور الجامع لخير الدنيا والآخرة',
    ),
    TasbeehItem(
      id: 29,
      text: 'لا إله إلا الله الملك الحق المبين',
      targetCount: 33,
      fadl: 'تهليل وتعظيم لملك الله وسلطانه',
    ),
    TasbeehItem(
      id: 30,
      text: 'سبحان الله وبحمده',
      targetCount: 100,
      fadl: 'من قالها مائة مرة غفرت ذنوبه وإن كانت مثل زبد البحر',
    ),
    TasbeehItem(
      id: 31,
      text: 'سبحان الله العظيم وبحمده',
      targetCount: 33,
      fadl: 'غرست له نخلة في الجنة',
    ),
    TasbeehItem(
      id: 32,
      text: 'اللهم إني أعوذ بك من الهم والحزن، والعجز والكسل، والجبن والبخل، وضلع الدين وغلبة الرجال',
      targetCount: 3,
      fadl: 'استعاذة جامعة من أثقال الحياة والهموم والديون',
    ),
    TasbeehItem(
      id: 33,
      text: 'رب اشرح لي صدري ويسر لي أمري واحلل عقدة من لساني يفقهوا قولي',
      targetCount: 33,
      fadl: 'دعاء التيسير والبركة وانشراح الصدر',
    ),
    TasbeehItem(
      id: 34,
      text: 'اللهم إني أسألك الهدى والتقى والعفاف والغنى',
      targetCount: 33,
      fadl: 'دعاء جامع لأسباب سعادة الدارين',
    ),
    TasbeehItem(
      id: 35,
      text: 'رب إني لما أنزلت إلي من خير فقير',
      targetCount: 33,
      fadl: 'دعاء نبي الله موسى عليه السلام لجلب الرزق وتيسير الأمر',
    ),
  ];

  @override
  List<TasbeehItem> getDefaultItems() => List.unmodifiable(_defaults);
}
