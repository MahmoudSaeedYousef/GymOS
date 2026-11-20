import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/current_inside_member_model.dart';
import '../services/attendance_api_service.dart';

final currentInsideProvider =
    FutureProvider.autoDispose<List<CurrentInsideMemberModel>>((ref) async {
  final api = ref.watch(attendanceApiProvider);
  return api.getCurrentInside();
});
