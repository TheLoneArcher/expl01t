import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camp_x/utils/user_provider.dart';
import 'package:camp_x/services/instructor_service.dart';
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
                return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
              }
              if (!marksSnapshot.hasData || marksSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No marks records found."));
              }

              // Also fetch Exam totals for percentage calculation
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('classes').doc('BTECH_3').collection('exams').snapshots(),
                builder: (context, examsSnapshot) {
                  if (!examsSnapshot.hasData) return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));

                  final marksDocs = marksSnapshot.data!.docs;
                  final examDocs = examsSnapshot.data!.docs;
                  
                  if (_isGraphView) {
                    return _buildGrowthGraph(marksDocs, examDocs, theme);
                  }

                  // Map exam name to total marks for List view
                  final Map<String, int> examTotals = {
                    for (var doc in examDocs) 
                      (doc.data() as Map)['name'] as String : ((doc.data() as Map)['totalMarks'] as num).toInt()
                  };
                  return _buildListView(marksDocs, examTotals, user, targetUid);
                }
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> docs, Map<String, int> examTotals, Map<String, dynamic>? user, String targetUid) {
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
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: ExpansionTile(
            title: Text(examName, style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
            subtitle: Text("Total Possible: $totalMax"),
            trailing: user?['role'] == 'instructor' 
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditMarksDialog(context, targetUid, examName, marks),
                  ) 
                : null,
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

  void _showEditMarksDialog(BuildContext context, String uid, String examId, Map<String, dynamic> currentMarks) async {
    final Map<String, int> marks = Map<String, int>.from(currentMarks.map((k, v) => MapEntry(k, (v as num).toInt())));
    
    // Fetch subjects
    final subjectsSnapshot = await FirebaseFirestore.instance.collection('subjects').get();
    final subjects = subjectsSnapshot.docs.map((doc) => doc.data()['name'] as String).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Marks: $examId"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: subjects.map((sub) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                initialValue: marks[sub]?.toString() ?? '',
                decoration: InputDecoration(labelText: sub, hintText: 'Enter Marks'),
                keyboardType: TextInputType.number,
                onChanged: (val) => marks[sub] = int.tryParse(val) ?? 0,
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final result = await InstructorService().assignMarks(
                uid: uid,
                examId: examId,
                marks: marks,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
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
                   lineColors[i % lineColors.length].withValues(alpha: 0.15),
                   lineColors[i % lineColors.length].withValues(alpha: 0.2),
                 ],
               ),
             ),
           ),
         );
       }
    }

    return Center(
      child: Container(
        height: 300, 
        width: 600,
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
               child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("Performance Trends", style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                 Icon(Icons.auto_graph, size: 16, color: theme.primaryColor.withValues(alpha: 0.7)),
               ],
             )),
             const Divider(height: 1),
             Expanded(
               child: Padding(
                  padding: const EdgeInsets.only(right: 24, left: 12, top: 16, bottom: 12),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < examNames.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    examNames[index].substring(0, 3).toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                          left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                      ),
                      minX: 0,
                      maxX: (examNames.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: lineBarsData,
                    ),
                  ),
               ),
             ),
             
             const Divider(height: 1),
             
             // Legend Area
             Padding(
               padding: const EdgeInsets.all(12.0),
               child: SizedBox(
                 height: 30,
                 child: ListView.builder(
                   scrollDirection: Axis.horizontal,
                   itemCount: subjectsList.length,
                   itemBuilder: (context, i) {
                     return Container(
                       margin: const EdgeInsets.only(right: 16),
                       child: Row(
                         children: [
                           Container(
                             width: 8,
                             height: 8,
                             decoration: BoxDecoration(
                               color: lineColors[i % lineColors.length],
                               shape: BoxShape.circle,
                             ),
                           ),
                           const SizedBox(width: 6),
                           Text(
                             subjectsList[i],
                             style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     );
                   },
                 ),
               ),
             ),
          ],
        ),
      ),
    );

  }
}

