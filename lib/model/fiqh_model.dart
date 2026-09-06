import 'package:flutter/material.dart';

/// تصنيفات كتب الفقه الإسلامي
enum FiqhCategory {
  ibadat('العبادات', Icons.mosque_rounded),
  muamalat('المعاملات والمال', Icons.account_balance_rounded),
  family('الأسرة والأحوال الشخصية', Icons.family_restroom_rounded),
  general('الآداب والأحكام العامة', Icons.menu_book_rounded);

  final String label;
  final IconData icon;
  const FiqhCategory(this.label, this.icon);
}

/// أنواع الأحكام الشرعية التكليفية والوضعية
enum FiqhRulingType {
  fard('فرض / ركن', Color(0xFF1B5E20), Color(0xFFE8F5E9)),
  wajib('واجب', Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  sunnah('سنة / مستحب', Color(0xFF0277BD), Color(0xFFE1F5FE)),
  mubah('مباح', Color(0xFF546E7A), Color(0xFFECEFF1)),
  makruh('مكروه', Color(0xFFE65100), Color(0xFFFFF3E0)),
  haram('حرام / محظور', Color(0xFFC62828), Color(0xFFFFEBEE)),
  bayan('حكم شرعي', Color(0xFF6D4C41), Color(0xFFEFEBE9));

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const FiqhRulingType(
    this.label,
    this.foregroundColor,
    this.backgroundColor,
  );
}

/// الدليل الشرعي من الكتاب أو السنة
class FiqhEvidence {
  final String text;
  final String source;
  final bool isQuran;

  const FiqhEvidence({
    required this.text,
    required this.source,
    this.isQuran = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'source': source,
        'isQuran': isQuran,
      };

  factory FiqhEvidence.fromJson(Map<String, dynamic> json) => FiqhEvidence(
        text: json['text'] as String? ?? '',
        source: json['source'] as String? ?? '',
        isQuran: json['isQuran'] as bool? ?? false,
      );
}

/// مسألة أو حكم فقهي محدد داخل الباب
class FiqhIssue {
  final String id;
  final String title;
  final FiqhRulingType rulingType;
  final String content;
  final List<FiqhEvidence> evidences;
  final List<String> conditions;
  final List<String> notes;

  const FiqhIssue({
    required this.id,
    required this.title,
    required this.rulingType,
    required this.content,
    this.evidences = const [],
    this.conditions = const [],
    this.notes = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'rulingType': rulingType.name,
        'content': content,
        'evidences': evidences.map((e) => e.toJson()).toList(),
        'conditions': conditions,
        'notes': notes,
      };

  factory FiqhIssue.fromJson(Map<String, dynamic> json) => FiqhIssue(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        rulingType: FiqhRulingType.values.firstWhere(
          (e) => e.name == json['rulingType'],
          orElse: () => FiqhRulingType.bayan,
        ),
        content: json['content'] as String? ?? '',
        evidences: (json['evidences'] as List<dynamic>?)
                ?.map((e) => FiqhEvidence.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        conditions: (json['conditions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        notes: (json['notes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// باب فقهي يتفرع من أحد كتب الفقه
class FiqhChapter {
  final String id;
  final String bookId;
  final String title;
  final String summary;
  final List<FiqhIssue> issues;

  const FiqhChapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.summary,
    required this.issues,
  });

  int get issuesCount => issues.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'summary': summary,
        'issues': issues.map((i) => i.toJson()).toList(),
      };
}

/// كتاب فقهي رئيسي (مثال: كتاب الطهارة، كتاب الصلاة، كتاب البيوع)
class FiqhBook {
  final String id;
  final String title;
  final String subtitle;
  final FiqhCategory category;
  final IconData icon;
  final List<FiqhChapter> chapters;

  const FiqhBook({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.chapters,
  });

  int get chaptersCount => chapters.length;
  int get totalIssuesCount =>
      chapters.fold(0, (sum, chapter) => sum + chapter.issuesCount);
}

/// إشارة مرجعية / حفظ مسألة في المفضلة
class FiqhBookmark {
  final String issueId;
  final String chapterId;
  final String bookId;
  final String issueTitle;
  final String chapterTitle;
  final String bookTitle;
  final String snippet;
  final DateTime savedAt;

  const FiqhBookmark({
    required this.issueId,
    required this.chapterId,
    required this.bookId,
    required this.issueTitle,
    required this.chapterTitle,
    required this.bookTitle,
    required this.snippet,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'issueId': issueId,
        'chapterId': chapterId,
        'bookId': bookId,
        'issueTitle': issueTitle,
        'chapterTitle': chapterTitle,
        'bookTitle': bookTitle,
        'snippet': snippet,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FiqhBookmark.fromJson(Map<String, dynamic> json) => FiqhBookmark(
        issueId: json['issueId'] as String? ?? '',
        chapterId: json['chapterId'] as String? ?? '',
        bookId: json['bookId'] as String? ?? '',
        issueTitle: json['issueTitle'] as String? ?? '',
        chapterTitle: json['chapterTitle'] as String? ?? '',
        bookTitle: json['bookTitle'] as String? ?? '',
        snippet: json['snippet'] as String? ?? '',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
