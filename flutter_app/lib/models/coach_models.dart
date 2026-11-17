class SuggestionCard {
  final String category; // 'training' | 'nutrition' | 'recovery'
  final String? code;    // stable text key, see core/l10n/coach_text.dart
  final Map<String, num> params;
  final String title;    // the server's Chinese text, shown when [code] is unknown
  final String body;
  final int    priority;

  const SuggestionCard({
    required this.category,
    this.code,
    this.params = const {},
    required this.title,
    required this.body,
    required this.priority,
  });

  factory SuggestionCard.fromJson(Map<String, dynamic> j) => SuggestionCard(
    category: j['category'] as String,
    code:     j['code']     as String?,
    params:   (j['params'] as Map<String, dynamic>? ?? const {})
        .map((k, v) => MapEntry(k, v as num)),
    title:    j['title']    as String,
    body:     j['body']     as String,
    priority: j['priority'] as int,
  );
}

class CoachSuggestionsResponse {
  final List<SuggestionCard> cards;
  final int                  dataPoints;

  const CoachSuggestionsResponse({
    required this.cards,
    required this.dataPoints,
  });

  factory CoachSuggestionsResponse.fromJson(Map<String, dynamic> j) =>
    CoachSuggestionsResponse(
      cards: (j['cards'] as List)
          .map((c) => SuggestionCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      dataPoints: j['data_points'] as int,
    );
}
