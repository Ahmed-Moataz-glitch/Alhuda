import 'package:flutter/material.dart';

/// تمثيل كتاب الحديث (صحيح البخاري، صحيح مسلم، الأربعون النووية)
class HadithBook {
  final String id;
  final int numericId;
  final String title;
  final String author;
  final String subtitle;
  final String badge;
  final int colorValue;
  final int totalHadiths;
  final int totalChapters;
  final String iconName;

  const HadithBook({
    required this.id,
    required this.numericId,
    required this.title,
    required this.author,
    required this.subtitle,
    required this.badge,
    required this.colorValue,
    required this.totalHadiths,
    required this.totalChapters,
    required this.iconName,
  });

  Color get color => Color(colorValue);

  IconData get icon {
    switch (iconName) {
      case 'auto_stories_rounded':
        return Icons.auto_stories_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'stars_rounded':
        return Icons.stars_rounded;
      default:
        return Icons.library_books_rounded;
    }
  }

  factory HadithBook.fromJson(Map<String, dynamic> json) => HadithBook(
        id: json['id'] as String,
        numericId: json['numericId'] as int? ?? 1,
        title: json['title'] as String,
        author: json['author'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        badge: json['badge'] as String? ?? '',
        colorValue: json['color'] as int? ?? 0xFF1B5E20,
        totalHadiths: json['totalHadiths'] as int? ?? 0,
        totalChapters: json['totalChapters'] as int? ?? 0,
        iconName: json['iconName'] as String? ?? 'menu_book_rounded',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'numericId': numericId,
        'title': title,
        'author': author,
        'subtitle': subtitle,
        'badge': badge,
        'color': colorValue,
        'totalHadiths': totalHadiths,
        'totalChapters': totalChapters,
        'iconName': iconName,
      };
}

/// تمثيل باب/فصل داخل كتاب الحديث
class HadithChapter {
  final int id;
  final String title;
  final int hadithsCount;
  final int startHadith;
  final int endHadith;

  const HadithChapter({
    required this.id,
    required this.title,
    required this.hadithsCount,
    required this.startHadith,
    required this.endHadith,
  });

  factory HadithChapter.fromJson(Map<String, dynamic> json) => HadithChapter(
        id: json['id'] as int,
        title: (json['title'] ?? json['arabic'] ?? '') as String,
        hadithsCount: json['hadithsCount'] as int? ?? 0,
        startHadith: json['startHadith'] as int? ?? 0,
        endHadith: json['endHadith'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hadithsCount': hadithsCount,
        'startHadith': startHadith,
        'endHadith': endHadith,
      };
}

/// تمثيل الحديث النبوي الشريف
class HadithItem {
  final int id;
  final int idInBook;
  final int chapterId;
  final int bookId;
  final String arabic;

  const HadithItem({
    required this.id,
    required this.idInBook,
    required this.chapterId,
    required this.bookId,
    required this.arabic,
  });

  factory HadithItem.fromJson(Map<String, dynamic> json) => HadithItem(
        id: json['id'] as int? ?? 0,
        idInBook: json['idInBook'] as int? ?? 0,
        chapterId: json['chapterId'] as int? ?? 1,
        bookId: json['bookId'] as int? ?? 1,
        arabic: json['arabic'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idInBook': idInBook,
        'chapterId': chapterId,
        'bookId': bookId,
        'arabic': arabic,
      };
}

/// إشارة مرجعية لحديث محفوظ في المفضلة
class HadithBookmark {
  final String bookId;
  final String bookTitle;
  final int chapterId;
  final String chapterTitle;
  final int hadithNumber;
  final String snippet;
  final String addedDate;

  const HadithBookmark({
    required this.bookId,
    required this.bookTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.hadithNumber,
    required this.snippet,
    required this.addedDate,
  });

  factory HadithBookmark.fromJson(Map<String, dynamic> json) => HadithBookmark(
        bookId: json['bookId'] as String? ?? '',
        bookTitle: json['bookTitle'] as String? ?? '',
        chapterId: json['chapterId'] as int? ?? 1,
        chapterTitle: json['chapterTitle'] as String? ?? '',
        hadithNumber: json['hadithNumber'] as int? ?? 1,
        snippet: json['snippet'] as String? ?? '',
        addedDate: json['addedDate'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'bookTitle': bookTitle,
        'chapterId': chapterId,
        'chapterTitle': chapterTitle,
        'hadithNumber': hadithNumber,
        'snippet': snippet,
        'addedDate': addedDate,
      };

  String get uniqueKey => '${bookId}_${chapterId}_$hadithNumber';
}

/// نتيجة بحث في موسوعة الأحاديث
class HadithSearchResult {
  final String bookId;
  final String bookTitle;
  final int chapterId;
  final String chapterTitle;
  final int hadithNumber;
  final String matchedSnippet;

  const HadithSearchResult({
    required this.bookId,
    required this.bookTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.hadithNumber,
    required this.matchedSnippet,
  });
}
