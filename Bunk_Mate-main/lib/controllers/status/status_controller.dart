import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bunk_mate/models/course_summary_model.dart';

class StatusController extends GetxController {
  final storage = const FlutterSecureStorage();

  StatusController() {
    getStatus();
  }

  var courses = <CourseSummary>[].obs;
  var isHoliday = false.obs;
  var selectedDate = DateTime.now().obs;
  var statusUpdate = false.obs;
  var courseStatuses = <String, int>{}.obs; // course_id to status (0=bunked, 1=present)

  Map<int, String> days = {
    1: "Monday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday"
  };

  Color c1 = Colors.white; // Initial color

  Future<String> getToken() async {
    dynamic token = await storage.read(key: 'token');
    return token;
  }

  Future<void> getStatus({DateTime? date}) async {
    final now = DateTime.now();
    final today = date ?? now;
    int dayOfWeek = today.weekday; // 1 = Monday, 7 = Sunday

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('courses')
          .select()
          .eq('user_id', user.id)
          .contains('day', [dayOfWeek]);

      courses.value = response.map((course) => CourseSummary.fromJson(course)).toList();

      // Fetch statuses for the selected date
      String dateStr = today.toIso8601String().split('T')[0];
      final statusResponse = await supabase
          .from('statuses')
          .select('id, status')
          .eq('user_id', user.id)
          .eq('date', dateStr);

      courseStatuses.clear();
      for (var statusEntry in statusResponse) {
        courseStatuses[statusEntry['id'].toString()] = statusEntry['status'];
      }

      statusUpdate.value = false;
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to retrieve status');
    }
  }

  Future<void> updateStatus(CourseSummary course, String status, {DateTime? date}) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      int currentStatus = courseStatuses[course.id.toString()] ?? 1;
      int newBunked = course.bunked;
      int newNoClasses = course.noClasses;

      if (status == 'bunked') {
        if (currentStatus == 1) {
          newNoClasses += 1;
          newBunked += 1;
        }
      } else if (status == 'present') {
        if (currentStatus == 0) {
          newBunked -= 1;
        }
      }

      // Ensure non-negative
      if (newBunked < 0) newBunked = 0;
      if (newNoClasses < 0) newNoClasses = 0;

      int bunksAvailable = (newNoClasses - newBunked - ((course.percentage / 100) * newNoClasses)).floor();
      if (bunksAvailable < 0) bunksAvailable = 0;
      double currentPercentage = newNoClasses > 0 ? (((newNoClasses - newBunked) / newNoClasses) * 100) : 0.0;

      await supabase.from('courses').update({
        'no_classes': newNoClasses,
        'bunked': newBunked,
        'bunks_available': bunksAvailable,
        'current_percentage': currentPercentage,
      }).eq('id', course.id);

      // Save to statuses table
      String dateStr = (date ?? selectedDate.value).toIso8601String().split('T')[0];
      int newStatusInt = status == 'bunked' ? 0 : 1;

      try {
        await supabase.from('statuses').insert({
          'user_id': user.id,
          'id': course.id,
          'date': dateStr,
          'status': newStatusInt,
        });
      } catch (e) {
        print('Error inserting status: $e');
        if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
          await supabase.from('statuses').update({
            'status': newStatusInt,
          }).eq('user_id', user.id).eq('id', course.id).eq('date', dateStr);
        } else {
          rethrow;
        }
      }

      courseStatuses[course.id.toString()] = newStatusInt;
      courseStatuses.refresh();

      await getStatus(date: date ?? selectedDate.value);
    } catch (e) {
      print('Error updating status: $e');
      throw Exception('Failed to update status');
    }
  }

  Future<void> addHoliday(int sourceDay) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      int targetDay = selectedDate.value.weekday;

      // Don't copy if source and target are the same
      if (sourceDay == targetDay) return;

      // First, delete existing courses for target day
      await supabase
          .from('courses')
          .delete()
          .eq('user_id', user.id)
          .eq('day', targetDay);

      // Get courses from source day
      final sourceCourses = await supabase
          .from('courses')
          .select()
          .eq('user_id', user.id)
          .eq('day', sourceDay);

      // Insert copies for target day
      for (var course in sourceCourses) {
        await supabase.from('courses').insert({
          'user_id': user.id,
          'name': course['name'],
          'no_classes': course['no_classes'],
          'percentage': course['percentage'],
          'bunks_available': course['bunks_available'],
          'bunked': course['bunked'],
          'current_percentage': course['current_percentage'],
          'day': targetDay,
        });
      }

      await getStatus(date: selectedDate.value);
      Get.snackbar("Success", "Schedule copied successfully!");
    } catch (e) {
      print('Error: $e');
      Get.snackbar("Error", "Failed to copy schedule");
    }
  }

  Future<void> selectDate(BuildContext context) async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101),
      );

      if (picked != null && picked != selectedDate.value) {
        selectedDate.value = picked;
        await getStatus(date: picked);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  IconData getRandomSubjectIcon() {
    var subjectIcons = [
      Icons.abc,
    ];
    var randomIndex = subjectIcons.isNotEmpty ? 0 : 0;
    return subjectIcons[randomIndex];
  }
}
