/// ResultsScreen displays summary statistics and score distribution for graded MCQ scripts.
///
/// ## Responsibilities
/// - Shows average, highest, and lowest scores.
/// - Displays the highest and lowest scoring students.
/// - Visualizes score distribution using a bar chart.
/// - Presents summary statistics in styled cards.
///
/// ## Parameters
/// - [test]: Test metadata.
/// - [scripts]: List of graded scripts.
/// - [endNumber]: Total number of questions.
/// - [averageScore]: Pre-calculated average score.
/// - [highestScore]: Pre-calculated highest score.
/// - [lowestScore]: Pre-calculated lowest score.
/// - [highestScorer]: Index number of highest scoring student.
/// - [lowestScorer]: Index number of lowest scoring student.
/// - [scoreDistribution]: Map of score values to their frequency.
///
/// ## Main Methods
/// - `_buildBarGroups`: Prepares bar chart data for score distribution.
///
/// ## Usage
/// Use this screen to review grading results and score analytics.
/// 
/// Example:
/// ```dart
/// ResultsScreen(
///   test: testData,
///   scripts: scriptsList,
///   endNumber: 50,
///   averageScore: avg,
///   highestScore: max,
///   lowestScore: min,
///   highestScorer: '12345',
///   lowestScorer: '54321',
///   scoreDistribution: scoreMap,
/// )
/// ```
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryTab extends StatelessWidget {
  final Map<String, dynamic>? test;
  final List scripts;
  final int endNumber;

  // New pre-calculated fields
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final String highestScorer;
  final String lowestScorer;
  final Map<int, int> scoreDistribution;

  const SummaryTab({
    Key? key,
    required this.test,
    required this.scripts,
    required this.endNumber,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.highestScorer,
    required this.lowestScorer,
    required this.scoreDistribution,
  }) : super(key: key);

  List<BarChartGroupData> _buildBarGroups(int endNumber) {
    if (scripts.isEmpty) return [];
    List<BarChartGroupData> barGroups = [];
    List sortedScores = scripts.map((s) => s['score'] ?? 0).toList()..sort();
    final Map<int, int> scoreDistribution = {};

    for (var score in sortedScores) {
      if (score is int) {
        scoreDistribution[score] = (scoreDistribution[score] ?? 0) + 1;
      }
    }

    scoreDistribution.forEach((score, count) {
      barGroups.add(
        BarChartGroupData(
          x: score,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: const Color.fromRGBO(29, 53, 87, 1.0),
              width: 15,
            ),
          ],
        ),
      );
    });

    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color.fromRGBO(29, 53, 87, 1.0);
    const Color secondaryColor = Color.fromRGBO(168, 218, 220, 1.0);

    return scripts.isEmpty
        ? const Center(
            child: Text(
              'No summary data available. Scan some scripts first!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Summary Statistics',
                    style: TextStyle(
                      fontFamily: 'Rampart_One',
                      fontSize: 24,
                      color: Color.fromRGBO(29, 53, 87, 1.0),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Average Score',
                          value: averageScore.toStringAsFixed(2),
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: 'Highest Score',
                          value: highestScore.toStringAsFixed(0),
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: 'Lowest Score',
                          value: lowestScore.toStringAsFixed(0),
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SummaryCard(
                    title: 'Highest Scorer',
                    value: highestScorer,
                    color: Colors.lightGreenAccent.shade100,
                  ),
                  const SizedBox(height: 10),
                  SummaryCard(
                    title: 'Lowest Scorer',
                    value: lowestScorer,
                    color: Colors.redAccent.shade100,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Score Distribution',
                    style: TextStyle(
                      fontFamily: 'Rampart_One',
                      fontSize: 24,
                      color: Color.fromRGBO(29, 53, 87, 1.0),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BarChart(
                          BarChartData(
                            barGroups: _buildBarGroups(endNumber),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toInt().toString(),
                                        style: const TextStyle(
                                            color: primaryColor, fontSize: 12));
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 10,
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toInt().toString(),
                                        style: const TextStyle(
                                            color: primaryColor, fontSize: 12));
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                // ignore: deprecated_member_use
                                color: primaryColor.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                // ignore: deprecated_member_use
                                color: primaryColor.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: primaryColor, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color.fromRGBO(29, 53, 87, 1.0);
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}