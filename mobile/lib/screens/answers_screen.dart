/// AnswersScreen displays a student's answers for an MCQ script.
///
/// ## Responsibilities
/// - Shows each question's student answer and correct answer side by side.
/// - Highlights correct and incorrect answers with color and icons.
/// - Displays a summary of correct, incorrect, and total answers at the bottom.
///
/// ## Parameters
/// - [indexNumber]: Student's index number.
/// - [answers]: List of answer objects with 'answer' and 'correct_answer'.
/// - [endNumber]: Total number of questions.
///
/// ## Main Methods
/// - `_buildScoreItem`: Formats score summary items.
/// - `_calculateCorrectAnswers`: Counts correct answers.
/// - `_calculateIncorrectAnswers`: Counts incorrect answers.
///
/// ## Usage
/// Navigate to this screen to view a student's answer breakdown.
/// 
/// Example:
/// ```dart
/// AnswersScreen(
///   indexNumber: '12345',
///   answers: studentAnswers,
///   endNumber: 50,
/// )
/// ```
import 'package:flutter/material.dart';

class AnswersScreen extends StatelessWidget {
  final String indexNumber;
  final List<dynamic> answers;
  final int endNumber;

  const AnswersScreen({
    Key? key,
    required this.indexNumber,
    required this.answers,
    required this.endNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
      appBar: AppBar(
        title: Text(
          indexNumber,
          style: const TextStyle(
            fontFamily: 'Rampart_One',
            color: Color.fromRGBO(29, 53, 87, 1.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromRGBO(29, 53, 87, 1.0),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(168, 218, 220, 0.3),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: const Color.fromRGBO(168, 218, 220, 1.0),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'STUDENT ANSWERS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        color: Color.fromRGBO(29, 53, 87, 1.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Questions: ${answers.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Orbitron',
                        color: Color.fromRGBO(69, 123, 157, 1.0),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Questions List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: answers.length,
                itemBuilder: (context, index) {
                  final answer = answers[index];
                  final studentAnswer = answer['answer']?.toString() ?? 'N/A';
                  final correctAnswer = answer['correct_answer']?.toString() ?? 'N/A';
                  final isCorrect = (studentAnswer.toLowerCase() == correctAnswer.toLowerCase()) &&
                  !['X', 'M'].contains(studentAnswer);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isCorrect 
                            ? Colors.green.shade300 
                            : Colors.red.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCorrect 
                              ? Colors.green.shade100 
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              color: isCorrect 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'STUDENT ANSWER',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Orbitron',
                                    color: Color.fromRGBO(69, 123, 157, 1.0),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCorrect 
                                        ? Colors.green.shade50 
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    studentAnswer.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                      color: isCorrect 
                                          ? Colors.green.shade700 
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CORRECT ANSWER',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Orbitron',
                                    color: Color.fromRGBO(69, 123, 157, 1.0),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    correctAnswer.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              
              // Summary Footer
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(168, 218, 220, 0.3),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: const Color.fromRGBO(168, 218, 220, 1.0),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SCORE SUMMARY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        color: Color.fromRGBO(29, 53, 87, 1.0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildScoreItem(
                          'CORRECT',
                          _calculateCorrectAnswers().toString(),
                          Colors.green,
                        ),
                        _buildScoreItem(
                          'INCORRECT',
                          _calculateIncorrectAnswers().toString(),
                          Colors.red,
                        ),
                        _buildScoreItem(
                          'TOTAL',
                          '${_calculateCorrectAnswers()}/${answers.length}',
                          const Color.fromRGBO(69, 123, 157, 1.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Orbitron',
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.0),
            // ignore: deprecated_member_use
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  int _calculateCorrectAnswers() {
    int correct = 0;
    for (var answer in answers) {
      final studentAnswer = answer['answer']?.toString().toLowerCase() ?? '';
      final correctAnswer = answer['correct_answer']?.toString().toLowerCase() ?? '';
      if ((studentAnswer == correctAnswer) && !['X', 'M'].contains(studentAnswer)) {
        correct++;
      }
    }
    return correct;
  }

  int _calculateIncorrectAnswers() {
    return answers.length - _calculateCorrectAnswers();
  }
}