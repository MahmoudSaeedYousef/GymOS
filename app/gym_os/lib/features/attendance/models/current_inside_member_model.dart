import '../../../l10n/app_localizations.dart';

class CurrentInsideMemberModel {
  final String recordId;
  final String memberId;
  final String fullName;
  final String phoneNumber;
  final DateTime checkInTime;
  final String? photoUrl;
  final int gender;

  CurrentInsideMemberModel({
    required this.recordId,
    required this.memberId,
    required this.fullName,
    required this.phoneNumber,
    required this.checkInTime,
    this.photoUrl,
    this.gender = 0,
  });

  /// Returns the number of minutes elapsed since the check-in time.
  int get elapsedMinutes => DateTime.now().difference(checkInTime).inMinutes;

  /// Returns a human-friendly Arabic relative time string (legacy fallback).
  String get formattedElapsedTime {
    final minutes = elapsedMinutes;
    if (minutes < 1) {
      return 'الآن';
    } else if (minutes < 60) {
      return 'منذ $minutes دقيقة';
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      if (remainingMins == 0) {
        return 'منذ $hours ساعة';
      }
      return 'منذ $hours ساعة و $remainingMins د';
    }
  }

  /// Returns a localized relative time string using [AppLocalizations].
  String localizedElapsedTime(AppLocalizations l10n) {
    final minutes = elapsedMinutes;
    if (minutes < 1) {
      return l10n.timeJustNow;
    } else if (minutes < 60) {
      return l10n.timeMinutesAgo(minutes);
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      if (remainingMins == 0) {
        return l10n.timeHoursAgo(hours);
      }
      return l10n.timeHoursAndMinutesAgo(hours, remainingMins);
    }
  }

  factory CurrentInsideMemberModel.fromJson(Map<String, dynamic> json) {
    return CurrentInsideMemberModel(
      recordId: json['recordId']?.toString() ?? json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      fullName: json['fullName'] ?? json['memberName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      checkInTime: _parseUtcToLocal(json['checkInTime']),
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
      gender: (json['gender'] is int)
          ? json['gender'] as int
          : int.tryParse(json['gender']?.toString() ?? '') ?? 0,
    );
  }

  static DateTime _parseUtcToLocal(dynamic raw) {
    if (raw == null) return DateTime.now();
    final str = raw.toString();
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return DateTime.now();
    if (parsed.isUtc) return parsed.toLocal();
    // Parse as UTC if string doesn't specify timezone, then convert to local
    return DateTime.tryParse('${str}Z')?.toLocal() ?? parsed.toLocal();
  }
}
