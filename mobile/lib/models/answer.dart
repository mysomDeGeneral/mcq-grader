class Answer {
  final String id;
  final String questionId;
  final String selectedOption;
  final bool isCorrect;
  final String imageUrl;

  Answer({
    required this.id,
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    this.imageUrl = '',
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['question_id'],
      selectedOption: json['selected_option'],
      isCorrect: json['is_correct'],
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'selected_option': selectedOption,
      'is_correct': isCorrect,
      'image_url': imageUrl,
    };
  }
}