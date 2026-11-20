import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../models/current_inside_member_model.dart';

/// Stream provider for members currently inside the facility, reading reactively from Drift.
final currentInsideProvider =
    StreamProvider.autoDispose<List<CurrentInsideMemberModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.attendanceDao.watchCurrentlyCheckedIn().map((list) {
    return list
        .map((a) => CurrentInsideMemberModel(
              recordId: a.id,
              memberId: a.memberId ?? '',
              fullName: a.memberName,
              phoneNumber: a.memberPhone ?? '',
              checkInTime: a.checkInTime,
            ))
        .toList();
  });
});
