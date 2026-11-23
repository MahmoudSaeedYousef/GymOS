import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../models/current_inside_member_model.dart';

/// Stream provider for members currently inside the facility, reading reactively from Drift.
final currentInsideProvider =
    StreamProvider.autoDispose<List<CurrentInsideMemberModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.attendanceDao.watchCurrentlyCheckedIn().asyncMap((list) async {
    final memberIds = list
        .map((a) => a.memberId)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();

    Map<String, String?> photoMap = {};
    if (memberIds.isNotEmpty) {
      final members = await (db.select(db.localMembers)
            ..where((t) => t.id.isIn(memberIds)))
          .get();
      photoMap = {
        for (final m in members) m.id: m.photoUrl,
      };
    }

    return list
        .map((a) => CurrentInsideMemberModel(
              recordId: a.id,
              memberId: a.memberId ?? '',
              fullName: a.memberName,
              phoneNumber: a.memberPhone ?? '',
              checkInTime: a.checkInTime,
              photoUrl: a.memberId != null ? photoMap[a.memberId] : null,
            ))
        .toList();
  });
});
