class AboutContent {
  final String key;
  final String valueEs;
  final String valueEn;

  AboutContent({required this.key, required this.valueEs, required this.valueEn});

  factory AboutContent.fromJson(Map<String, dynamic> json) {
    return AboutContent(
      key: json['key'],
      valueEs: json['value_es'] ?? '',
      valueEn: json['value_en'] ?? '',
    );
  }

  String localizedValue(bool isSpanish, String companyName) {
    String text = isSpanish ? valueEs : valueEn;
    return text.replaceAll(RegExp(r'\[?\s*NOMBRE\s+AGENCIA\s*\]?', caseSensitive: false), companyName);
  }
}

class FaqEntry {
  final String id;
  final String questionEs;
  final String answerEs;
  final String questionEn;
  final String answerEn;
  final int sortOrder;

  FaqEntry({
    required this.id,
    required this.questionEs,
    required this.answerEs,
    required this.questionEn,
    required this.answerEn,
    required this.sortOrder,
  });

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    return FaqEntry(
      id: json['id'],
      questionEs: json['question_es'] ?? '',
      answerEs: json['answer_es'] ?? '',
      questionEn: json['question_en'] ?? '',
      answerEn: json['answer_en'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  String localizedQuestion(bool isSpanish, String companyName) {
    String text = isSpanish ? questionEs : questionEn;
    return text.replaceAll(RegExp(r'\[?\s*NOMBRE\s+AGENCIA\s*\]?', caseSensitive: false), companyName);
  }

  String localizedAnswer(bool isSpanish, String companyName) {
    String text = isSpanish ? answerEs : answerEn;
    return text.replaceAll(RegExp(r'\[?\s*NOMBRE\s+AGENCIA\s*\]?', caseSensitive: false), companyName);
  }
}
