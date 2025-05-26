import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PoetryService {
  static const String _apiKey = 'AIzaSyCKKMc7lHPqB70NbmG5DHcJpAvr6Sb_LeY';

  static Future<void> maybeGeneratePoetryOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastPoetryFetchDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastDate == today) {
      print("📅 Poetry already fetched today.");
      return;
    }

    await generateAndUploadPoetry();
    await prefs.setString('lastPoetryFetchDate', today);
  }

  /// 🌞 Generates a featured poem (Ghalib/Rumi/Iqbal only)
  static Future<void> generateAndUploadPoetry() async {
    try {
      final model = GenerativeModel(
        model: 'models/gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = Content.text("""
Pick a real, existing Urdu poem written by Mirza Ghalib, Rumi, or Allama Iqbal (translated or original).

Return:
- The full poem (8+ lines)
- A short stanza (4–6 lines) excerpted directly from that full poem
- The title and author
- A one-word mood tag (e.g. love, longing, spiritual, hopeful)

Strictly follow this clean JSON format (no extra comments or text):

{
  "title": "Title of the poem",
  "author": "Ghalib / Rumi / Iqbal",
  "mood": "hopeful",
  "stanza": "Short excerpt (4–6 lines from within the poem)",
  "poem": "The full poem text (8+ lines)"
}
""");

      final response = await model.generateContent([prompt]);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception('Empty Gemini response');
      }

      final json = _extractJson(text);
      if (json == null) throw Exception("Invalid or missing JSON");

      final title = json['title']?.trim();
      final author = json['author']?.trim();
      final mood = json['mood']?.trim();
      final stanza = json['stanza']?.trim();
      final fullPoem = json['poem']?.trim();

      if ([title, author, stanza, fullPoem].any((e) => e == null || e.isEmpty)) {
        throw Exception("Incomplete fields from Gemini");
      }

      final stanzaText = stanza?.toString().trim() ?? '';
        final lines = stanzaText.split('\n');

        final highlightLine = lines.firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => lines.isNotEmpty ? lines.first : '',
        );



      // Check for duplicates
      final existing = await FirebaseFirestore.instance
          .collection('poem')
          .where('title', isEqualTo: title)
          .where('author', isEqualTo: author)
          .where('content', isEqualTo: fullPoem)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print("⚠️ Duplicate poem already exists. Skipping upload.");
        return;
      }

      // Unmark previous
      final oldPoems = await FirebaseFirestore.instance
          .collection('poem')
          .where('isPoetryOfTheDay', isEqualTo: true)
          .get();

      for (var doc in oldPoems.docs) {
        await doc.reference.update({'isPoetryOfTheDay': false});
      }

      // Upload new
      await FirebaseFirestore.instance.collection('poem').add({
        'title': title,
        'author': author,
        'moodTag': mood ?? 'unknown',
        'stanza': stanza,
        'content': fullPoem,
        'highlightLine': highlightLine,
        'isPoetryOfTheDay': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ New Poetry of the Day uploaded successfully.");
    } catch (e) {
      print("❌ Error in PoetryService: $e");
    }
  }

  static Future<Map<String, dynamic>?> generatePoemByMood(String mood) async {
    try {
      final model = GenerativeModel(
        model: 'models/gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = Content.text("""
Pick a real, existing poem (in English or Urdu) by one of the following poets:
- William Shakespeare
- Emily Dickinson
- Mirza Ghalib
- Rumi
- Allama Iqbal

The poem should match the mood: "$mood".

Return the following strictly in clean JSON (no comments or explanations):

{
  "title": "Title of the poem",
  "author": "Shakespeare / Dickinson / Auden / Ghalib / Rumi / Iqbal",
  "mood": "$mood",
  "stanza": "Short excerpt (4–6 lines from the poem)",
  "poem": "Full poem (8+ lines)"
}
""");

      final response = await model.generateContent([prompt]);
      final text = response.text;

      if (text == null || text.trim().isEmpty) return null;

      final jsonData = _extractJson(text);
      if (jsonData == null) return null;

      final title = jsonData['title']?.trim();
      final author = jsonData['author']?.trim();
      final stanza = jsonData['stanza']?.trim();
      final content = jsonData['poem']?.trim();
      final moodTag = jsonData['mood']?.trim() ?? mood;

      if ([title, author, stanza, content].any((e) => e == null || e.isEmpty)) {
        return null;
      }

      final stanzaText = stanza?.toString().trim() ?? '';
        final lines = stanzaText.split('\n');

        final highlightLine = lines.firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => lines.isNotEmpty ? lines.first : '',
        );



      // Check for duplicates
      final existing = await FirebaseFirestore.instance
          .collection('poem')
          .where('title', isEqualTo: title)
          .where('author', isEqualTo: author)
          .where('content', isEqualTo: content)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print("⚠️ Duplicate mood poem already exists.");
        return {
          'id': existing.docs.first.id,
          'title': title,
          'author': author,
          'mood': moodTag,
          'stanza': stanza,
          'fullPoem': content,
        };
      }

      final docRef = await FirebaseFirestore.instance.collection('poem').add({
        'title': title,
        'author': author,
        'moodTag': moodTag,
        'stanza': stanza,
        'content': content,
        'highlightLine': highlightLine,
        'isPoetryOfTheDay': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'id': docRef.id,
        'title': title,
        'author': author,
        'mood': moodTag,
        'stanza': stanza,
        'fullPoem': content,
      };
    } catch (e) {
      print("❌ Error generating mood poem: $e");
      return null;
    }
  }


static Map<String, dynamic>? _extractJson(String text) {
  try {
    // Remove any markdown formatting or extra noise
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Find the first and last curly braces to extract the JSON part
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonString = cleaned.substring(start, end + 1);

    // Parse using dart:convert
    return json.decode(jsonString);
  } catch (e) {
    print("❌ JSON parsing failed: $e");
    return null;
  }
}




  /// Explore by Title + Author
static Future<Map<String, dynamic>?> searchPoemByTitleAndAuthor(String title, String author) async {
  final model = GenerativeModel(
    model: 'models/gemini-1.5-flash',
    apiKey: _apiKey,
  );

  final prompt = Content.text("""
You are a poetry assistant. The user will provide a poem title and the poet's name.
Only return a real, existing poem by that poet. If no matching poem is found, return:

{
  "error": "Poem not found"
}

Otherwise, return a clean JSON object in the following format:

{
  "title": "Title of the poem",
  "author": "Poet name",
  "mood": "One-word mood",
  "stanza": "Short 4–6 line excerpt",
  "poem": "The full poem text (8+ lines)"
}

Poem title: "$title"
Poet: "$author"
""");

  final response = await model.generateContent([prompt]);
  final text = response.text;
  if (text == null || text.trim().isEmpty) return null;

  final jsonData = _extractJson(text);
  if (jsonData == null || jsonData['error'] != null) return null;

  return _uploadIfValid(jsonData);
}

/// Explore by searching a line
static Future<Map<String, dynamic>?> searchPoemByLine(String line) async {
  final model = GenerativeModel(
    model: 'models/gemini-1.5-flash',
    apiKey: _apiKey,
  );

  final prompt = Content.text("""
You are a poetry search assistant. The user provides a line from a real poem.
Search your training data for a real, published poem that contains that line.

If the line is not found in any real poem, return:

{
  "error": "Poem not found"
}

Otherwise, return in this clean JSON format (no extra text or explanation):

{
  "title": "Title of the poem",
  "author": "Poet name",
  "mood": "One-word mood",
  "stanza": "Short excerpt (4–6 lines)",
  "poem": "Full poem text (8+ lines)"
}

Line: "$line"
""");

  final response = await model.generateContent([prompt]);
  final text = response.text;
  if (text == null || text.trim().isEmpty) return null;

  final jsonData = _extractJson(text);
  if (jsonData == null || jsonData['error'] != null) return null;

  return _uploadIfValid(jsonData);
}

/// Helper to validate and optionally upload result
static Future<Map<String, dynamic>?> _uploadIfValid(Map<String, dynamic> jsonData) async {
  final title = jsonData['title']?.trim();
  final author = jsonData['author']?.trim();
  final mood = jsonData['mood']?.trim() ?? 'unknown';
  final stanza = jsonData['stanza']?.trim();
  final poem = jsonData['poem']?.trim();

  if ([title, author, stanza, poem].any((e) => e == null || e.isEmpty)) return null;

  final stanzaText = stanza?.toString().trim() ?? '';
    final lines = stanzaText.split('\n');

    final highlightLine = lines.firstWhere(
      (String line) => line.trim().isNotEmpty,
      orElse: () => lines.isNotEmpty ? lines.first : '',
    );


  final existing = await FirebaseFirestore.instance
      .collection('poem')
      .where('title', isEqualTo: title)
      .where('author', isEqualTo: author)
      .where('content', isEqualTo: poem)
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) {
    return {
      'id': existing.docs.first.id,
      'title': title,
      'author': author,
      'mood': mood,
      'stanza': stanza,
      'fullPoem': poem,
    };
  }

  final docRef = await FirebaseFirestore.instance.collection('poem').add({
    'title': title,
    'author': author,
    'moodTag': mood,
    'stanza': stanza,
    'content': poem,
    'highlightLine': highlightLine,
    'isPoetryOfTheDay': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  return {
    'id': docRef.id,
    'title': title,
    'author': author,
    'mood': mood,
    'stanza': stanza,
    'fullPoem': poem,
  };
}
static Future<String> generateStarterLines(String mood) async {
  final model = GenerativeModel(
    model: 'models/gemini-1.5-flash',
    apiKey: _apiKey,
  );

  final prompt = Content.text("""
Generate 2 original poetic lines in $mood mood to help a user start their poem.
Only return the 2 lines, no title or extra text.
""");

  final response = await model.generateContent([prompt]);
  final text = response.text?.trim();
  if (text == null || text.isEmpty) throw Exception("Empty AI response");

  return text;
}


}
