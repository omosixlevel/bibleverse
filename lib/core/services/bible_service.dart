import 'dart:convert';
import 'package:flutter/services.dart';

class BibleService {
  List<dynamic>? _enKjv;
  List<dynamic>? _frSegond;

  static const String VERSION_KJV = 'en_kjv';
  static const String VERSION_LSG = 'fr_segond';

  static const Map<String, String> _bookNamesKJV = {
    'gn': 'Genesis',
    'ex': 'Exodus',
    'lv': 'Leviticus',
    'nm': 'Numbers',
    'dt': 'Deuteronomy',
    'js': 'Joshua',
    'jud': 'Judges',
    'rt': 'Ruth',
    '1sm': '1 Samuel',
    '2sm': '2 Samuel',
    '1kgs': '1 Kings',
    '2kgs': '2 Kings',
    '1ch': '1 Chronicles',
    '2ch': '2 Chronicles',
    'ezr': 'Ezra',
    'ne': 'Nehemiah',
    'et': 'Esther',
    'job': 'Job',
    'ps': 'Psalms',
    'prv': 'Proverbs',
    'ec': 'Ecclesiastes',
    'so': 'Song of Solomon',
    'is': 'Isaiah',
    'jr': 'Jeremiah',
    'lm': 'Lamentations',
    'ez': 'Ezekiel',
    'dn': 'Daniel',
    'ho': 'Hosea',
    'jl': 'Joel',
    'am': 'Amos',
    'ob': 'Obadiah',
    'jn': 'Jonah',
    'mi': 'Micah',
    'na': 'Nahum',
    'hk': 'Habakkuk',
    'zp': 'Zephaniah',
    'hg': 'Haggai',
    'zc': 'Zechariah',
    'ml': 'Malachi',
    'mt': 'Matthew',
    'mk': 'Mark',
    'lk': 'Luke',
    'jo': 'John',
    'act': 'Acts',
    'rm': 'Romans',
    '1co': '1 Corinthians',
    '2co': '2 Corinthians',
    'gl': 'Galatians',
    'eph': 'Ephesians',
    'ph': 'Philippians',
    'cl': 'Colossians',
    '1ts': '1 Thessalonians',
    '2ts': '2 Thessalonians',
    '1tm': '1 Timothy',
    '2tm': '2 Timothy',
    'tt': 'Titus',
    'phm': 'Philemon',
    'hb': 'Hebrews',
    'jm': 'James',
    '1pe': '1 Peter',
    '2pe': '2 Peter',
    '1jo': '1 John',
    '2jo': '2 John',
    '3jo': '3 John',
    'jd': 'Jude',
    're': 'Revelation',
  };

  static const Map<String, String> _bookNamesLSG = {
    'gn': 'Genèse',
    'ex': 'Exode',
    'lv': 'Lévitique',
    'nm': 'Nombres',
    'dt': 'Deutéronome',
    'js': 'Josué',
    'jud': 'Juges',
    'rt': 'Ruth',
    '1sm': '1 Samuel',
    '2sm': '2 Samuel',
    '1kgs': '1 Rois',
    '2kgs': '2 Rois',
    '1ch': '1 Chroniques',
    '2ch': '2 Chroniques',
    'ezr': 'Esdras',
    'ne': 'Néhémie',
    'et': 'Esther',
    'job': 'Job',
    'ps': 'Psaumes',
    'prv': 'Proverbes',
    'ec': 'Ecclésiaste',
    'so': 'Cantique des Cantiques',
    'is': 'Ésaïe',
    'jr': 'Jérémie',
    'lm': 'Lamentations',
    'ez': 'Ézéchiel',
    'dn': 'Daniel',
    'ho': 'Osée',
    'jl': 'Joël',
    'am': 'Amos',
    'ob': 'Abdias',
    'jn': 'Jonas',
    'mi': 'Michée',
    'na': 'Nahum',
    'hk': 'Habacuc',
    'zp': 'Sophonie',
    'hg': 'Aggée',
    'zc': 'Zacharie',
    'ml': 'Malachie',
    'mt': 'Matthieu',
    'mk': 'Marc',
    'lk': 'Luc',
    'jo': 'Jean',
    'act': 'Actes',
    'rm': 'Romains',
    '1co': '1 Corinthiens',
    '2co': '2 Corinthiens',
    'gl': 'Galates',
    'eph': 'Éphésiens',
    'ph': 'Philippiens',
    'cl': 'Colossiens',
    '1ts': '1 Thessaloniciens',
    '2ts': '2 Thessaloniciens',
    '1tm': '1 Timothée',
    '2tm': '2 Timothée',
    'tt': 'Tite',
    'phm': 'Philémon',
    'hb': 'Hébreux',
    'jm': 'Jacques',
    '1pe': '1 Pierre',
    '2pe': '2 Pierre',
    '1jo': '1 Jean',
    '2jo': '2 Jean',
    '3jo': '3 Jean',
    'jd': 'Jude',
    're': 'Apocalypse',
  };

  List<Map<String, String>> getVersions() {
    return [
      {'id': VERSION_KJV, 'name': 'KJV (English)'},
      {'id': VERSION_LSG, 'name': 'Segond 1910 (Français)'},
    ];
  }

  Future<void> loadBibles() async {
    if (_enKjv == null) {
      final String enString = await rootBundle.loadString(
        'assets/bible/en_kjv.json',
      );
      _enKjv = jsonDecode(enString);
    }
    if (_frSegond == null) {
      final String frString = await rootBundle.loadString(
        'assets/bible/segond_1910.json',
      );
      _frSegond = jsonDecode(frString);
    }
  }

  List<String> getBooks(String version) {
    final data = version == VERSION_LSG ? _frSegond : _enKjv;
    if (data == null) return [];

    final map = version == VERSION_LSG ? _bookNamesLSG : _bookNamesKJV;

    return data.map((b) {
      final abbrev = b['abbrev'].toString();
      return map[abbrev] ?? abbrev;
    }).toList();
  }

  String? _getAbbrev(String version, String bookName) {
    final map = version == VERSION_LSG ? _bookNamesLSG : _bookNamesKJV;
    final entry = map.entries.firstWhere(
      (e) => e.value.toLowerCase() == bookName.toLowerCase(),
      orElse: () => const MapEntry('', ''),
    );
    return entry.key.isEmpty ? null : entry.key;
  }

  int getChapterCount(String version, String bookName) {
    final data = version == VERSION_LSG ? _frSegond : _enKjv;
    if (data == null) return 0;

    final abbrev = _getAbbrev(version, bookName);
    if (abbrev == null) return 0;

    final book = data.firstWhere(
      (b) => b['abbrev'].toString().toLowerCase() == abbrev.toLowerCase(),
      orElse: () => null,
    );
    if (book == null) return 0;
    return (book['chapters'] as List).length;
  }

  List<String> getChapterVerses(String version, String bookName, int chapter) {
    final data = version == VERSION_LSG ? _frSegond : _enKjv;
    if (data == null) return [];

    try {
      final abbrev = _getAbbrev(version, bookName);
      if (abbrev == null) return [];

      final book = data.firstWhere(
        (b) => b['abbrev'].toString().toLowerCase() == abbrev.toLowerCase(),
        orElse: () => null,
      );
      if (book == null) return [];
      final chapters = book['chapters'] as List;
      if (chapter < 1 || chapter > chapters.length) return [];
      return (chapters[chapter - 1] as List).map((v) => v.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  String? getVerse(String version, String bookAbbrev, int chapter, int verse) {
    final data = version == 'fr_segond' ? _frSegond : _enKjv;
    if (data == null) return null;

    try {
      final book = data.firstWhere(
        (b) => b['abbrev'].toString().toLowerCase() == bookAbbrev.toLowerCase(),
        orElse: () => null,
      );

      if (book == null) return null;

      final chapters = book['chapters'] as List;
      if (chapter < 1 || chapter > chapters.length) return null;

      final verses = chapters[chapter - 1] as List;
      if (verse < 1 || verse > verses.length) return null;

      return verses[verse - 1].toString();
    } catch (e) {
      print('Error getting verse: $e');
      return null;
    }
  }
}
