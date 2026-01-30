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
                  
                  if (_isGraphView) {
                    return _buildGrowthGraph(marksDocs, examDocs, theme);
                  }

                  // Map exam name to total marks for List view
                  final Map<String, int> examTotals = {
                    for (var doc in examDocs) (doc.data() as Map)['name'] : (doc.data() as Map)['totalMarks'] ?? 100
                  };
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

  Widget _buildGrowthGraph(List<QueryDocumentSnapshot> marksDocs, List<QueryDocumentSnapshot> examDocs, ThemeData theme) {
    // 1. Map Exam metadata
    final Map<String, dynamic> examMeta = {
      for (var doc in examDocs) 
        (doc.data() as Map)['name'] : {
          'date': ((doc.data() as Map)['date'] as Timestamp).toDate(),
          'total': (doc.data() as Map)['totalMarks'] ?? 100,
        }
    };

    // 2. Sort marksDocs by exam date
    final sortedMarksDocs = List<QueryDocumentSnapshot>.from(marksDocs);
    sortedMarksDocs.sort((a, b) {
      final nameA = (a.data() as Map)['examId'];
      final nameB = (b.data() as Map)['examId'];
      final dateA = examMeta[nameA]?['date'] ?? DateTime(2000);
      final dateB = examMeta[nameB]?['date'] ?? DateTime(2000);
      return dateA.compareTo(dateB);
    });

    // 3. Find unique subjects
    Set<String> allSubjects = {};
    for (var doc in sortedMarksDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final marks = Map<String, dynamic>.from(data)..remove('examId');
      allSubjects.addAll(marks.keys);
    }
    final subjectsList = allSubjects.toList()..sort();

    final List<Color> lineColors = [
      const Color(0xFF00F2FF), // Neon Cyan
      const Color(0xFF70FF00), // Neon Green
      const Color(0xFFFFCC00), // Neon Yellow
      const Color(0xFFFF00D4), // Neon Pink
      const Color(0xFF007BFF), // Deep Blue
      const Color(0xFFFF4D00), // Bright Orange
      const Color(0xFF8A2BE2), // Violet
      const Color(0xFF00FF9C), // Seafoam
    ];

    final List<String> examNames = sortedMarksDocs.map((doc) => (doc.data() as Map<String, dynamic>)['examId'] as String).toList();

    List<LineChartBarData> lineBarsData = [];
    for (int i = 0; i < subjectsList.length; i++) {
       String subject = subjectsList[i];
       List<FlSpot> spots = [];
       
       for (int x = 0; x < sortedMarksDocs.length; x++) {
         final data = sortedMarksDocs[x].data() as Map<String, dynamic>;
         final examName = data['examId'] ?? 'Exam';
         final totalMax = examMeta[examName]?['total'] ?? 100;
         
         if (data.containsKey(subject)) {
           double score = (data[subject] as num).toDouble();
           spots.add(FlSpot(x.toDouble(), score / totalMax * 100));
         }
       }

       if (spots.length > 1) {
         lineBarsData.add(
           LineChartBarData(
             spots: spots,
             isCurved: true,
             curveSmoothness: 0.3,
             color: lineColors[i % lineColors.length],
             barWidth: 3,
             isStrokeCapRound: true,
             dotData: FlDotData(
               show: true,
               getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                 radius: 4,
                 color: theme.scaffoldBackgroundColor,
                 strokeWidth: 2,
                 strokeColor: lineColors[i % lineColors.length],
               ),
             ),
             belowBarData: BarAreaData(
               show: true,
               gradient: LinearGradient(
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
                 colors: [
                   lineColors[i % lineColors.length].withOpacity(0.15),
                   lineColors[i % lineColors.length].withOpacity(0.0),
                 ],
               ),
             ),
           ),
         );
       }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "SUCCESS TRACKER",
                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor, letterSpacing: 1.2),
                ),
                const Icon(Icons.analytics_outlined, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 24),
            
            // Legend
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: subjectsList.length,
                itemBuilder: (context, i) {
                  return Container(
                    margin: const EdgeInsets.only(right: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: lineColors[i % lineColors.length],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: lineColors[i % lineColors.length].withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          subjectsList[i].toUpperCase(),
                          style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 30),
            
            AspectRatio(
              aspectRatio: 1.4,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, left: 12, bottom: 12),
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        maxContentWidth: 150,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${subjectsList[spot.barIndex]}\n',
                              GoogleFonts.orbitron(color: lineColors[spot.barIndex % lineColors.length], fontWeight: FontWeight.bold, fontSize: 10),
                              children: [
                                TextSpan(
                                  text: '${spot.y.toStringAsFixed(1)}%',
                                  style: GoogleFonts.exo2(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 25,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                      getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < examNames.length) {
                               String name = examNames[index];
                               if (name.length > 5) name = name.substring(0, 4) + '..';
                               return SideTitleWidget(
                                 meta: meta,
                                 space: 10,
                                 child: Text(name.toUpperCase(), style: GoogleFonts.orbitron(fontSize: 7, color: Colors.grey, fontWeight: FontWeight.bold)),
                               );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text('${value.toInt()}%', style: GoogleFonts.exo2(fontSize: 10, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (examNames.length - 1).toDouble().clamp(0.1, 100),
                    minY: 0,
                    maxY: 110, // Margin at top
                    lineBarsData: lineBarsData,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoNote("Showing growth across ${examNames.length} evaluated examinations."),
          ],
        ),
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

