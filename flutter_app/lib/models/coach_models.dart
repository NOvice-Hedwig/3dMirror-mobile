class SuggestionCard {
  final String category; // 'training' | 'nutrition' | 'recovery'
  final String title;
  final String body;
  final int    priority;

  const SuggestionCard({
    required this.category,
    required this.title,
    required this.body,
    required this.priority,
  });

  factory SuggestionCard.fromJson(Map<String, dynamic> j) => SuggestionCard(
    category: j['category'] as String,
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
