import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camp_x/utils/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class MarksTab extends StatefulWidget {
  final String? studentId;
  const MarksTab({super.key, this.studentId});

  @override
  State<MarksTab> createState() => _MarksTabState();
}

class _MarksTabState extends State<MarksTab> {
  bool _isGraphView = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final targetUid = widget.studentId ?? user?['uid'];
    final theme = Theme.of(context);

    if (targetUid == null) return const Center(child: Text("No user data"));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isGraphView ? "Academic Growth (%)" : "Detailed Records",
                style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: Icon(_isGraphView ? Icons.list_alt : Icons.show_chart),
                onPressed: () => setState(() => _isGraphView = !_isGraphView),
                tooltip: _isGraphView ? "Switch to List View" : "Switch to Growth Graph",
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(targetUid)
                .collection('marks')
                .snapshots(),
            builder: (context, marksSnapshot) {
              if (marksSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!marksSnapshot.hasData || marksSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No marks records found."));
              }

              // Also fetch Exam totals for percentage calculation
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('classes').doc('BTECH_3').collection('exams').snapshots(),
                builder: (context, examsSnapshot) {
                  if (!examsSnapshot.hasData) return const LinearProgressIndicator();

                  final marksDocs = marksSnapshot.data!.docs;
                  final examDocs = examsSnapshot.data!.docs;
                  
                  // Map exam name to total marks
                  final Map<String, int> examTotals = {
                    for (var doc in examDocs) (doc.data() as Map)['name'] : (doc.data() as Map)['totalMarks'] ?? 100
                  };

                  if (_isGraphView) {
                    return _buildGrowthGraph(marksDocs, examTotals, theme);
                  }

                  return _buildListView(marksDocs, examTotals);
                }
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> docs, Map<String, int> examTotals) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final examName = data['examId'] ?? 'Exam';
        final marks = Map<String, dynamic>.from(data)..remove('examId');
        final totalMax = examTotals[examName] ?? 100;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ExpansionTile(
            title: Text(examName, style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
            subtitle: Text("Total Possible: $totalMax"),
            children: marks.entries.map((e) {
              final score = (e.value as num).toDouble();
              final perc = (score / totalMax * 100).toStringAsFixed(1);
              return ListTile(
                title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text("Raw Score: $score / $totalMax"),
                trailing: Text(
                  "$perc%",
                  style: GoogleFonts.exo2(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildGrowthGraph(List<QueryDocumentSnapshot> docs, Map<String, int> examTotals, ThemeData theme) {
    // Calculate average percentage per exam
    final List<Map<String, dynamic>> chartData = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final examName = data['examId'] ?? 'Exam';
      final marks = Map<String, dynamic>.from(data)..remove('examId');
      final totalMax = examTotals[examName] ?? 100;
      
      double sumPerc = 0;
      marks.values.forEach((v) => sumPerc += (v as num).toDouble() / totalMax * 100);
      double avgPerc = marks.isEmpty ? 0 : sumPerc / marks.length;

      return {'name': examName, 'avg': avgPerc};
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "Overall Performance History",
            style: GoogleFonts.orbitron(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          AspectRatio(
            aspectRatio: 1.2,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.primaryColor.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${chartData[groupIndex]['name']}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < chartData.length) {
                          String name = chartData[idx]['name'];
                          // Shorten name if too long
                          if (name.length > 5) name = name.substring(0, 4) + '.';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text("${value.toInt()}%", style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.1))),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chartData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: chartData[i]['avg'],
                        color: theme.primaryColor,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: theme.primaryColor.withOpacity(0.05)),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildInfoNote("Graph shows Average % across all subjects for each examination."),
        ],
      ),
    );
  }

  Widget _buildInfoNote(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey))),
        ],
      ),
    );
  }
}

