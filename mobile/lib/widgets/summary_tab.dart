/// Widget for displaying summary statistics and score distribution for MCQ scripts.
///
/// ## Responsibilities
/// - Computes and displays total scripts, average score, highest and lowest scores (with index numbers).
/// - Visualizes score distribution using a pie chart.
/// - Presents summary and chart in styled info cards.
///
/// ## Parameters
/// - [scripts]: List of script data, each containing 'score' and 'index_number'.
/// - [endNumber]: Last script number (for future use).
/// - [test]: Optional test metadata.
///
/// ## Main Methods
/// - `_buildSummaryItem`: Formats a summary statistic row.
/// - `_buildInfoCard`: Creates a styled card for summary or chart.
/// - `_buildPieChart`: Renders a pie chart of score distribution.
///
/// ## Dependencies
/// - [fl_chart]: For pie chart visualization.
/// - [Orbitron] font: For text styling.
///
/// ## Usage
/// Place this widget in your UI to show grading results summary.
/// 
/// Example:
/// ```dart
/// SummaryTab(
///   scripts: myScripts,
///   endNumber: 50,
///   test: myTestInfo,
/// )
/// ```
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryTab extends StatelessWidget {
  final List<dynamic> scripts;
  final int endNumber;
  final Map<String, dynamic>? test;

  const SummaryTab({
    Key? key,
    required this.scripts,
    required this.endNumber,
    this.test,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (scripts.isEmpty) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    // Compute summary statistics
    int totalScripts = scripts.length;
    int totalActualScore = 0;
    double highestScore = 0;
    double lowestScore = double.infinity;
    String highestScorer = "";
    String lowestScorer = "";
    Map<int, int> scoreDistribution = {};

    for (var script in scripts) {
      double score =
          (script['score'] as num?)?.toDouble() ?? 0.0;
      totalActualScore += score.toInt();

      if (score > highestScore) {
        highestScore = score;
        highestScorer = script['index_number'] ?? "";
      }

      if (score < lowestScore) {
        lowestScore = score;
        lowestScorer = script['index_number'] ?? "";
      }

      int roundedScore = score.round();
      scoreDistribution[roundedScore] =
          (scoreDistribution[roundedScore] ?? 0) + 1;
    }

    double averageScore =
        totalScripts > 0 ? totalActualScore / totalScripts : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // Header Card
          _buildInfoCard(
            title: "SUMMARY STATISTICS",
            children: [
              _buildSummaryItem("Total Scripts", totalScripts.toString()),
              _buildSummaryItem("Average Score", averageScore.toStringAsFixed(2)),
              _buildSummaryItem("Highest Score", "$highestScorer ($highestScore)"),
              _buildSummaryItem("Lowest Score", "$lowestScorer ($lowestScore)"),
            ],
          ),
          const SizedBox(height: 20),
          // Score Distribution Card
          _buildInfoCard(
            title: "SCORE DISTRIBUTION",
            children: [
              SizedBox(
                height: 300,
                child: _buildPieChart(scoreDistribution),
              ),
              // You can add a legend here if you'd like
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Orbitron', color: Color.fromRGBO(29, 53, 87, 1.0)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(69, 123, 157, 1.0), fontFamily: 'Orbitron'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              color: Color.fromRGBO(29, 53, 87, 1.0),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Pie Chart for Score Distribution
  Widget _buildPieChart(Map<int, int> scoreDistribution) {
    if (scoreDistribution.isEmpty) {
      return const Center(child: Text("No score data available"));
    }
    return PieChart(
      PieChartData(
        sections: scoreDistribution.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.key}',
            color: Colors.primaries[entry.key % Colors.primaries.length],
            radius: 80, // Increased radius for a larger pie chart
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 4, // Increased space between sections
        centerSpaceRadius: 60, // Increased center space
      ),
      swapAnimationDuration: const Duration(milliseconds: 150),
      swapAnimationCurve: Curves.linear,
    );
  }
}