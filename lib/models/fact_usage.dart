/// How one fact did since the last report. It carries no installation id,
/// because the server only ever adds these numbers to a shared total.
class FactUsage {
  const FactUsage({
    this.shown = 0,
    this.liked = 0,
    this.opened = 0,
    this.shared = 0,
    this.quizCorrect = 0,
    this.quizWrong = 0,
  });

  factory FactUsage.fromJson(Map<String, dynamic> json) {
    return FactUsage(
      shown: json['shown'] as int,
      liked: json['liked'] as int,
      opened: json['opened'] as int,
      shared: json['shared'] as int,
      quizCorrect: json['quiz_correct'] as int,
      quizWrong: json['quiz_wrong'] as int,
    );
  }

  final int shown;
  final int liked;
  final int opened;
  final int shared;
  final int quizCorrect;
  final int quizWrong;

  FactUsage operator +(FactUsage other) {
    return FactUsage(
      shown: shown + other.shown,
      liked: liked + other.liked,
      opened: opened + other.opened,
      shared: shared + other.shared,
      quizCorrect: quizCorrect + other.quizCorrect,
      quizWrong: quizWrong + other.quizWrong,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shown': shown,
      'liked': liked,
      'opened': opened,
      'shared': shared,
      'quiz_correct': quizCorrect,
      'quiz_wrong': quizWrong,
    };
  }
}
