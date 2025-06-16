class Poem {
  final String id;
  final String author;
  final String content;
  final DateTime? createdAt;
  final String highlightLine;
  final bool isPoetryOfTheDay;
  final String moodTag;
  final String stanza;
  final String title;

  Poem({
    required this.id,
    required this.author,
    required this.content,
    this.createdAt,
    required this.highlightLine,
    required this.isPoetryOfTheDay,
    required this.moodTag,
    required this.stanza,
    required this.title,
  });

  factory Poem.fromMap(String id, Map<String, dynamic> data) {
    return Poem(
      id: id,
      author: data['author'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt']?.toDate(),
      highlightLine: data['highlightLine'] ?? '',
      isPoetryOfTheDay: data['isPoetryOfTheDay'] ?? false,
      moodTag: data['moodTag'] ?? '',
      stanza: data['stanza'] ?? '',
      title: data['title'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'mood': moodTag, 
      'stanza': stanza,
      'fullPoem': content,
    };
  }
}