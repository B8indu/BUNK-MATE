import 'dart:convert';
import 'dart:io';
import 'package:bunk_mate/models/time_table_model.dart';
import 'package:bunk_mate/models/course_summary_model.dart';
import 'package:bunk_mate/utils/api_endpoints.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class TimeTableController extends GetxController {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  var courses = <CourseSummary>[].obs;
  var schedule = <Schedule>[].obs;
  static const String apiUrl = ApiEndPoints.baseUrl;

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> getCourses() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('courses')
          .select()
          .eq('user_id', user.id);

      courses.value = response.map((course) => CourseSummary.fromJson(course)).toList();
    } catch (e) {
      Get.snackbar("Error", "Failed to load courses: $e");
    }
  }

  Future<void> getSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('${apiUrl}schedules'),
        headers: {
          HttpHeaders.authorizationHeader: "Token ${await getToken()}",
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        List<Schedule> tempSchedule = [];

        jsonResponse.forEach((day, courses) {
          tempSchedule.add(Schedule.fromJson(day, courses));
        });

        schedule.value = tempSchedule;
      } else {
        _handleError(response);
      }
    } catch (e) {
    }
  }

  Future<void> addSchedule(String url, int day) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          HttpHeaders.authorizationHeader: "Token ${await getToken()}",
          HttpHeaders.contentTypeHeader: "application/json"
        },
        body: jsonEncode({"day_of_week": day}),
      );

      if (response.statusCode == 201) {
        await getSchedule();
        Get.snackbar("Success", "Schedule has been added!");
      } else {
        _handleError(response);
      }
    } catch (e) {
    }
  }

  Future<void> addCourse(String courseName, List<int> days, int noClasses, int percentage, int bunked) async {
    if (courseName.isEmpty) {
      Get.snackbar("Error", "Course name cannot be empty");
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "User not logged in");
        return;
      }

      // Check if course name already exists for this user
      final existingCourses = await supabase
          .from('courses')
          .select('name')
          .eq('user_id', user.id)
          .eq('name', courseName);

      if (existingCourses.isNotEmpty) {
        Get.snackbar("Error", "A course with this name already exists");
        return;
      }

      double currentPercentage = noClasses > 0 ? ((noClasses - bunked) / noClasses) * 100 : 0.0;
      int bunksAvailable = (noClasses - bunked - ((percentage / 100) * noClasses)).floor();
      if (bunksAvailable < 0) bunksAvailable = 0;

      await supabase.from('courses').insert({
        'user_id': user.id,
        'name': courseName,
        'no_classes': noClasses,
        'percentage': percentage,
        'bunks_available': bunksAvailable,
        'bunked': bunked,
        'current_percentage': currentPercentage,
        'day': days,
      });

      await getCourses(); // Refresh courses
      Get.snackbar("Success", "Course has been added!");
    } catch (e) {
      Get.snackbar("Error", "Failed to add course: $e");
    }
  }

  Future<void> editCourse(String courseId, String courseName, List<int> days, int noClasses, int percentage, int bunked) async {
    if (courseName.isEmpty) {
      return;
    }

    double currentPercentage = noClasses > 0 ? ((noClasses - bunked) / noClasses) * 100 : 0.0;
    int bunksAvailable = (noClasses - bunked - ((percentage / 100) * noClasses)).floor();
    if (bunksAvailable < 0) bunksAvailable = 0;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "User not logged in");
        return;
      }

      await supabase
          .from('courses')
          .update({
            'name': courseName,
            'no_classes': noClasses,
            'percentage': percentage,
            'bunks_available': bunksAvailable,
            'bunked': bunked,
            'current_percentage': currentPercentage,
            'day': days,
          })
          .eq('id', courseId)
          .eq('user_id', user.id);

      await getCourses(); // Refresh courses
      Get.snackbar("Success", "Course has been updated!");
    } catch (e) {
      Get.snackbar("Error", "Failed to update course: $e");
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "User not logged in");
        return;
      }

      await supabase
          .from('courses')
          .delete()
          .eq('id', courseId)
          .eq('user_id', user.id);

      await getCourses(); // Refresh courses
      Get.snackbar("Success", "Course has been deleted!");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete course: $e");
    }
  }

  void _handleError(http.Response response) {
    String message;
    try {
      final responseBody = jsonDecode(response.body);
      message = responseBody['detail'] ?? 'Unknown error occurred';
    } catch (e) {
    }
  }
}
