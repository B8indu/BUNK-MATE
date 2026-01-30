import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bunk_mate/controllers/timetable/time_table_controller.dart';
import 'package:bunk_mate/models/course_summary_model.dart';

class TimeTableEntry extends StatefulWidget {
  const TimeTableEntry({Key? key}) : super(key: key);

  @override
  State<TimeTableEntry> createState() => _TimeTableEntryState();
}

class _TimeTableEntryState extends State<TimeTableEntry> {
  final TimeTableController controller = Get.put(TimeTableController());
  static const Map<int, String> days = {
    1: "Monday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday",
  };

  late final RxString _scheduleUrl = ''.obs;
  late List<int> _selectedDays = [];
  late String _course = "Course";
  late int _noClasses = 0;
  late int _percentage = 0;
  late int _bunked = 0;
  final TextEditingController _courseTextFieldController =
      TextEditingController();
  final TextEditingController _noClassesController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();
  final TextEditingController _bunkedController = TextEditingController();
  final TextEditingController _currentPercentageController = TextEditingController();

  static const Color bgColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color textColor = Colors.white;
  static const Color secondaryTextColor = Colors.white70;

  @override
  void initState() {
    super.initState();
    controller.getSchedule();
    controller.getCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      title: Text(
        'My Timetable',
        style: GoogleFonts.lexend(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return FutureBuilder(
      future: controller.getCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: accentColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: textColor)),
          );
        }

        return Obx(() {
          if (controller.courses.isEmpty) {
            return Center(
              child: Text(
                '📝 Set Up Your Timetable!\n\n'
                'Start by adding a course. Once you’ve done that:\n\n'
                '💡 Feel free to use the text box below for any extra courses you’d like to add!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Group courses by day
          Map<int, List<CourseSummary>> coursesByDay = {};
          for (var course in controller.courses) {
            List<int> courseDays = (course.day as List<dynamic>?)?.cast<int>() ?? [1];
            for (int day in courseDays) {
              coursesByDay.putIfAbsent(day, () => []).add(course);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: 7, // 7 days
            itemBuilder: (context, index) {
              int dayNumber = index + 1;
              List<CourseSummary> dayCourses = coursesByDay[dayNumber] ?? [];
              return _buildDayCard(dayNumber, dayCourses);
            },
          );
        });
      },
    );
  }

  Widget _buildDayCard(int dayNumber, List<CourseSummary> courses) {
    String dayName = days[dayNumber] ?? "Unknown";

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayName.toUpperCase(),
              style: GoogleFonts.poppins(
                color: accentColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              Text(
                'No courses scheduled',
                style: TextStyle(color: secondaryTextColor),
              )
            else
              ...courses.map((course) => _buildCourseItem(course)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(CourseSummary course) {
    return GestureDetector(
      onTap: () {
        // Handle tap if needed
      },
      onLongPress: () {
        _showDeleteDialog(course);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(getRandomSubjectIcon(), size: 28, color: accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bunks Available: ${course.bunksAvailable}',
                    style: GoogleFonts.poppins(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(CourseSummary course) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            "Course Options",
            style: TextStyle(color: textColor),
          ),
          content: Text(
            "What would you like to do with '${course.name}'?",
            style: TextStyle(color: textColor),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close the options dialog
                      // Use microtask to ensure dialog opens after current task completes
                      Future.microtask(() => _showDeleteDialog(course));
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Edit",
                      style: TextStyle(color: bgColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _showConfirmDeleteDialog(course.id);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDeleteDialog(String courseId) {
    // Find the course name for display
    final course = controller.courses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => CourseSummary(
        id: '',
        name: 'Unknown Course',
        noClasses: 0,
        bunked: 0,
        percentage: 0,
        currentPercentage: 0.0,
        bunksAvailable: 0,
        day: [],
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            "Delete Course",
            style: TextStyle(color: textColor),
          ),
          content: Text(
            "Are you sure you want to delete '${course.name}'?",
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.deleteCourse(courseId);
                Navigator.of(context).pop();
              },
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

void _showDeleteDialog(CourseSummary course) {
  showDialog(
  context: context,
  barrierDismissible: true,
  builder: (BuildContext dialogContext) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: bgColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Course',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _courseTextFieldController,
                      hintText: 'Enter your Course Name',
                      prefixIcon: Icons.book,
                      onChanged: (value) =>
                          _course = value.isEmpty ? "Course" : value,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _noClassesController,
                      hintText: 'Number of Classes',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _noClasses = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _percentageController,
                      hintText: 'Minimum Attendance Percentage',
                      prefixIcon: Icons.percent,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _percentage = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _bunkedController,
                      hintText:
                          'No. of Classes already bunked/absent',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _bunked = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 20),

                    _buildDaySelectionForDialog(setState),

                    const SizedBox(height: 24),
                    Center(child: _buildUpdateButton(course.id)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  },
);
}


  Widget _buildDaySelectionForDialog(StateSetter setState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Days',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.entries.map((day) {
              return FilterChip(
                label: Text(
                  day.value,
                  style: TextStyle(
                    color: _selectedDays.contains(day.key) ? bgColor : textColor,
                  ),
                ),
                selected: _selectedDays.contains(day.key),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day.key);
                    } else {
                      _selectedDays.remove(day.key);
                    }
                  });
                },
                backgroundColor: Colors.black12,
                selectedColor: accentColor,
                checkmarkColor: bgColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(String courseId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close edit dialog
              _showConfirmDeleteDialog(courseId);
            },
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => _updateCourse(courseId),
            child: Text(
              "Update",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateCourse(String courseId) {
    if (_course.isEmpty) {
      Get.snackbar("Error", "Please enter a course name");
      return;
    }
    if (_selectedDays.isEmpty) {
      Get.snackbar("Error", "Please select at least one day");
      return;
    }
    controller.editCourse(courseId, _course, _selectedDays, _noClasses, _percentage, _bunked);
    Get.snackbar("Success", "Course updated! Refresh to see changes.",
        backgroundColor: cardColor, colorText: textColor);

    Navigator.of(context).pop();
  }

  IconData getRandomSubjectIcon() {
    final icons = [
      Icons.book,
      Icons.science,
      Icons.calculate,
      Icons.language,
      Icons.history_edu,
      Icons.computer,
      Icons.music_note,
      Icons.palette,
      Icons.sports_basketball
    ];
    return icons[DateTime.now().microsecond % icons.length];
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddCourseBottomSheet(context),
      backgroundColor: accentColor,
      icon: const Icon(Icons.add, color: bgColor),
      label: Text(
        'Add Course',
        style: GoogleFonts.poppins(color: bgColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddCourseBottomSheet(BuildContext context) {
    // Reset fields for new course
    _courseTextFieldController.clear();
    _noClassesController.clear();
    _percentageController.clear();
    _bunkedController.clear();
    _selectedDays = [];
    _course = "Course";
    _noClasses = 0;
    _percentage = 0;
    _bunked = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            right: 20,
            left: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Add New Course',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _courseTextFieldController,
                hintText: 'Enter your Course Name',
                prefixIcon: Icons.book,
                onChanged: (value) => _course = value.isEmpty ? "Course" : value,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _noClassesController,
                hintText: 'Number of Classes',
                prefixIcon: Icons.numbers,
                keyboardType: TextInputType.number,
                onChanged: (value) => _noClasses = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _percentageController,
                hintText: 'Minimum Attendance Percentage',
                prefixIcon: Icons.percent,
                keyboardType: TextInputType.number,
                onChanged: (value) => _percentage = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _bunkedController,
                hintText: 'No. of Classes already bunked/absent',
                prefixIcon: Icons.numbers,
                keyboardType: TextInputType.number,
                onChanged: (value) => _bunked = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 20),
              _buildDaySelectionForDialog(setState),
              const SizedBox(height: 30),
              Center(child: _buildSubmitButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: secondaryTextColor),
        prefixIcon: Icon(prefixIcon, color: accentColor),
      ),
    );
  }

  Widget _buildDayDropdown() {
    return Container(); // Deprecated - using multi-select now
  }

  Widget _buildCourseDropdown() {
    return Container(); // Deprecated - using text field above
  }

  InputDecoration _getDropdownDecoration(
      {required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      hintText: hintText,
      hintStyle: const TextStyle(color: secondaryTextColor),
      prefixIcon: Icon(prefixIcon, color: accentColor),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: _submitForm,
      child: Text(
        "Add Course",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  void _submitForm() {
    if (_course.isEmpty) {
      Get.snackbar("Error", "Please enter a course name");
      return;
    }
    if (_selectedDays.isEmpty) {
      Get.snackbar("Error", "Please select at least one day");
      return;
    }
    controller.addCourse(_course, _selectedDays, _noClasses, _percentage, _bunked);
    Get.snackbar("Success", "Course added! Refresh to see changes.",
        backgroundColor: cardColor, colorText: textColor);

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _courseTextFieldController.dispose();
    _noClassesController.dispose();
    _percentageController.dispose();
    _bunkedController.dispose();
    _currentPercentageController.dispose();
    super.dispose();
  }
}
