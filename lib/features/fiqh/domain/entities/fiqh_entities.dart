import 'package:alhuda/core/theme/theme_service.dart';
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
  fard('فرض / ركن', Color(0xFF1B5E20), Color(0xFFE8F5E9), Color(0xFF81C784), Color(0x334CAF50)),
  wajib('واجب', Color(0xFF2E7D32), Color(0xFFE8F5E9), Color(0xFFA5D6A7), Color(0x334CAF50)),
  sunnah('سنة / مستحب', Color(0xFF0277BD), Color(0xFFE1F5FE), Color(0xFF81D4FA), Color(0x3303A9F4)),
  mubah('مباح', Color(0xFF546E7A), Color(0xFFECEFF1), Color(0xFFB0BEC5), Color(0x3378909C)),
  makruh('مكروه', Color(0xFFE65100), Color(0xFFFFF3E0), Color(0xFFFFB74D), Color(0x33FF9800)),
  haram('حرام / محظور', Color(0xFFC62828), Color(0xFFFFEBEE), Color(0xFFEF9A9A), Color(0x33F44336)),
  bayan('حكم شرعي', Color(0xFF6D4C41), Color(0xFFEFEBE9), Color(0xFFD7CCC8), Color(0x338D6E63));

  final String label;
  final Color _fgLight;
  final Color _bgLight;
  final Color _fgDark;
  final Color _bgDark;

  const FiqhRulingType(
    this.label,
    this._fgLight,
    this._bgLight,
    this._fgDark,
    this._bgDark,
  );

  Color get foregroundColor =>
      ThemeService.instance.isDarkMode ? _fgDark : _fgLight;

  Color get backgroundColor =>
      ThemeService.instance.isDarkMode ? _bgDark : _bgLight;
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

/// نتيجة بحث في الفقه الإسلامي
class FiqhSearchResult {
  final FiqhBook book;
  final FiqhChapter chapter;
  final FiqhIssue issue;
  final String matchedSnippet;

  const FiqhSearchResult({
    required this.book,
    required this.chapter,
    required this.issue,
    required this.matchedSnippet,
  });
}
