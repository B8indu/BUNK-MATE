import 'package:bunk_mate/screens/OnBoardView.dart';
import 'package:bunk_mate/screens/auth/login_screen.dart';
import 'package:bunk_mate/utils/Navigation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bunk_mate/controllers/homepage/course_summary_controller.dart';
import 'package:bunk_mate/controllers/auth/login_controller.dart';
import 'package:bunk_mate/models/course_summary_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final CourseSummaryController courseSummaryController =
      Get.put(CourseSummaryController());
  final LoginController loginController = Get.put(LoginController());

  final Color bgColor = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E1E);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color textColor = Colors.white;
  final Color secondaryTextColor = Colors.white70;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
       courseSummaryController.courseSummary.clear();
    await courseSummaryController.fetchCourseSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Bunk-Mate',
            style: TextStyle(
                color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        actions: [_buildPopupMenu()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: Obx(() {
            if (courseSummaryController.courseSummary.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: refreshData,
              child: ListView(
                children: [
                  const SizedBox(height: 30),
                  _buildOverallAttendance(),
                  const SizedBox(height: 30),
                  Text(
                    'Your Courses',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSubjectList(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<int>(
      itemBuilder: (context) => [
        PopupMenuItem(
            value: 0,
            child: Text("Update Timetable",
                style: TextStyle(color: textColor, fontSize: 16))),
        PopupMenuItem(
            value: 2,
            child: Text("Logout",
                style: TextStyle(color: textColor, fontSize: 16))),
      ],
      offset: const Offset(0, 50),
      color: cardColor,
      elevation: 2,
      icon: Icon(Icons.more_vert, color: textColor, size: 28),
      onSelected: _handleMenuSelection,
    );
  }

  void _handleMenuSelection(int value) async {
    if (value == 0) {
      Get.to(const TimetableView());
    } else if (value == 2) {
      await _handleLogout();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No courses available.\nAdd a course or update your timetable.",
        textAlign: TextAlign.center,
        style: TextStyle(color: secondaryTextColor, fontSize: 18.0),
      ),
    );
  }

  Widget _buildOverallAttendance() {
    double overallAttendance = courseSummaryController.courseSummary
            .map((subject) => subject.currentPercentage)
            .reduce((a, b) => a + b) /
        courseSummaryController.courseSummary.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Attendance',
            style: TextStyle(color: secondaryTextColor, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '${overallAttendance.toStringAsFixed(1)}%',
            style: TextStyle(
              color: _getOverallAttendanceColor(overallAttendance),
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    // Group courses by day
    Map<int, List<CourseSummary>> coursesByDay = {};
    for (var course in courseSummaryController.courseSummary) {
      List<int> courseDays = (course.day as List<dynamic>?)?.cast<int>() ?? [1];
      for (int day in courseDays) {
        coursesByDay.putIfAbsent(day, () => []).add(course);
      }
    }

    List<Widget> dayWidgets = [];
    Map<int, String> days = {
      1: "Monday",
      2: "Tuesday", 
      3: "Wednesday",
      4: "Thursday",
      5: "Friday",
      6: "Saturday",
      7: "Sunday",
    };

    for (int day = 1; day <= 7; day++) {
      List<CourseSummary> dayCourses = coursesByDay[day] ?? [];
      if (dayCourses.isNotEmpty) {
        dayWidgets.add(_buildDaySection(days[day]!, dayCourses));
      }
    }

    return Column(
      children: dayWidgets,
    );
  }

  Widget _buildDaySection(String dayName, List<CourseSummary> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            dayName.toUpperCase(),
            style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
        ),
        ...courses.map((course) => _buildSubjectTile(course)),
      ],
    );
  }

  Widget _buildSubjectTile(CourseSummary subject) {
    double percentage = subject.currentPercentage;
    return GestureDetector(
      onTap: () => _showCourseDetails(subject),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${percentage.toStringAsFixed(1)}% Attendance",
                    style: TextStyle(
                        color: _getAttendanceColor(percentage, subject.percentage),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bunks Available: ${subject.bunksAvailable}",
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: AttendanceArcPainter(percentage, subject.percentage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double current, double target) {
    if (current < target) return const Color(0xFFF44336); // red
    double diff = (current - target).abs();
    if (diff > 15) return const Color(0xFF4CAF50); // green
    if (diff >= 2) return const Color(0xFFFFA000); // orange
    return const Color(0xFF4CAF50); // green
  }

  Color _getOverallAttendanceColor(double percentage) {
    if (percentage <= 15) return const Color(0xFFF44336); // red
    if (percentage <= 50) return const Color(0xFFFFA000); // orange
    return const Color(0xFF4CAF50); // green
  }

  Future<List<String>> _fetchBunkedDates(String courseId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('statuses')
          .select('date')
          .eq('user_id', user.id)
          .eq('id', courseId)
          .eq('status', 0);

      return response.map((e) => e['date'] as String).toList();
    } catch (e) {
      print('Error fetching bunked dates: $e');
      return [];
    }
  }

  Future<void> _handleLogout() async {
    bool success = await loginController.logoutfunction();
    if (!success) {
      Get.off(const AuthScreen());
      Get.snackbar("Logout Successful", "You were logged out successfully");
      Get.deleteAll();
    } else {
      Get.snackbar("Error", "You weren't logged out. Try again.");
      Get.to(const Navigation());
    }
  }

  void _showCourseDetails(CourseSummary course) async {
    List<String> dates = await _fetchBunkedDates(course.id);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            course.name,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Classes: ${course.noClasses}",
                style: TextStyle(color: textColor),
              ),
              Text(
                "Minimum Percentage: ${course.percentage}",
                style: TextStyle(color: textColor),
              ),
              ExpansionTile(
                title: Text(
                  "Classes Bunked: ${course.bunked}",
                  style: TextStyle(color: textColor),
                ),
                children: dates.map((date) => ListTile(
                  title: Text(
                    date,
                    style: TextStyle(color: textColor),
                  ),
                )).toList(),
              ),
              Text(
                "Current Attendance: ${course.currentPercentage.toStringAsFixed(1)}%",
                style: TextStyle(color: _getAttendanceColor(course.currentPercentage, course.percentage)),
              ),
              Text(
                "Bunks Available: ${course.bunksAvailable}",
                style: TextStyle(color: secondaryTextColor),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: AttendanceArcPainter(course.currentPercentage, course.percentage),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Close",
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AttendanceArcPainter extends CustomPainter {
  final double current;
  final double target;

  AttendanceArcPainter(this.current, this.target);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -3.14159, 3.14159, false, backgroundPaint); // 180 degrees

    // Foreground arc
    final foregroundPaint = Paint()
      ..color = _getArcColor(current, target)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (current / 100) * 3.14159; // 180 degrees max
    canvas.drawArc(rect, -3.14159, sweepAngle, false, foregroundPaint);

    // Percentage text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${current.toStringAsFixed(0)}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  Color _getArcColor(double current, double target) {
    if (current < target) return const Color(0xFFF44336); // red
    double diff = (current - target).abs();
    if (diff > 15) return const Color(0xFF4CAF50); // green
    if (diff >= 2) return const Color(0xFFFFA000); // orange
    return const Color(0xFF4CAF50); // green
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
