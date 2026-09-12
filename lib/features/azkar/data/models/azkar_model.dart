// ignore_for_file: public_member_api_docs, sort_constructors_first
class AzkarModel {
  final String title;
  final String content;
  final bool isPressed;

  AzkarModel({
    required this.title,
    required this.content,
    this.isPressed = false,
  });

  AzkarModel copyWith({String? title, String? content, bool? isPressed}) {
    return AzkarModel(
      title: title ?? this.title,
      content: content ?? this.content,
      isPressed: isPressed ?? this.isPressed,
    );
  }
}

List<AzkarModel> azkar = [
  AzkarModel(
    title: 'دعاء دخول المسجد', 
    content: 'اللهم افتح لي أبواب رحمتك', 
  ),
  AzkarModel(
    title: 'دعاء الخروج من المسجد', 
    content: 'اللهم إني أسألك من فضلك', 
  ),
  AzkarModel(
    title: 'دعاء الاستيقاظ من النوم', 
    content: 'الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور', 
  ),
  AzkarModel(
    title: 'دعاء قبل النوم', 
    content: 'باسمك اللهم أموت وأحيا', 
  ),
  AzkarModel(
    title: 'دعاء الخروج من المنزل', 
    content: 'بسم الله توكلت على الله ولا حول ولا قوة إلا بالله اللهم إني أعوذ بك أن أضل أو أُضل أو أذل أو أُذل أو أظلم أو أُظلم أو أجهل أو يُجهل علىّ', 
  ),
  AzkarModel(
    title: 'دعاء الذهاب الى المسجد', 
    content: 'اللهم اجعل في قلبي نوراً وفي لساني نوراً وفي سمعي نوراً وفي بصري نوراً ومن فوقي نوراً ومن تحتي نوراً وعن يميني نوراً وعن شمالي نوراً ومن أمامي نوراً ومن خلفي نوراً واجعلني نوراً', 
  ),
];
