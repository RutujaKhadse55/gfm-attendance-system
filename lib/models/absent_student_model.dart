import 'attendance_model.dart';
import 'student_model.dart';
import 'followup_model.dart';

class AbsentStudentDetail {
  final Student student;
  final Attendance attendance;
  final FollowUp? followUp;

  AbsentStudentDetail({
    required this.student,
    required this.attendance,
    this.followUp,
  });
}
