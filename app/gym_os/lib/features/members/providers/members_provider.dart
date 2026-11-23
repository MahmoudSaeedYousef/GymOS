import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/daos/members_dao.dart';
import '../../../core/database/database_provider.dart';
import '../models/member_filter.dart';
import '../models/member_model.dart';
import '../models/member_sort_option.dart';
import '../models/members_summary_data.dart';
import '../services/gym_api_service.dart';

export '../../plans/providers/plans_provider.dart'
    show plansProvider, activePlansProvider;
export '../models/member_filter.dart';
export '../models/member_sort_option.dart';
export '../models/members_summary_data.dart';

// 2. حالة قائمة المشتركين (State)
class MembersState {
  final List<MemberModel> members;
  final List<MemberModel> allMembers;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final MemberFilter selectedFilter;
  final MemberSortOption selectedSort;
  final String? error;

  const MembersState({
    this.members = const [],
    this.allMembers = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.selectedFilter = MemberFilter.all,
    this.selectedSort = MemberSortOption.newest,
    this.error,
  });

  /// Locally filters the fetched list for instant visual feedback.
  List<MemberModel> get filteredMembers {
    if (selectedFilter == MemberFilter.all) return members;
    return members.where((m) {
      switch (selectedFilter) {
        case MemberFilter.active:
          return m.subscriptionStatus.toLowerCase() == 'active';
        case MemberFilter.expiringSoon:
          return m.isExpiringSoon;
        case MemberFilter.expired:
          return m.subscriptionStatus.toLowerCase() != 'active';
        case MemberFilter.today:
          return true;
        case MemberFilter.all:
          return true;
      }
    }).toList();
  }

  MembersState copyWith({
    List<MemberModel>? members,
    List<MemberModel>? allMembers,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    MemberFilter? selectedFilter,
    MemberSortOption? selectedSort,
    String? error,
  }) {
    return MembersState(
      members: members ?? this.members,
      allMembers: allMembers ?? this.allMembers,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedSort: selectedSort ?? this.selectedSort,
      error: error,
    );
  }
}

// 3. الـ Notifier المسؤول عن إدارة البحث والـ Pagination والإضافة والفلترة والترتيب
class MembersNotifier extends StateNotifier<MembersState> {
  final GymApiService _apiService;
  final MembersDao? _membersDao;
  Timer? _debounceTimer;
  StreamSubscription? _membersSubscription;

  MembersNotifier(this._apiService, [this._membersDao])
      : super(const MembersState()) {
    _initStream();
    loadInitial();
  }

  void _initStream() {
    if (_membersDao == null) return;
    _membersSubscription = _membersDao.watchAllMembers().listen((list) {
      if (list.isNotEmpty) {
        final models = list
            .where((m) => !m.isGuest)
            .map((m) => MemberModel(
                  id: m.id,
                  fullName: m.fullName,
                  phoneNumber: m.phone,
                  photoUrl: m.photoUrl,
                  activePlanName: m.planName,
                  subscriptionEndDate:
                      m.subscriptionEndDate?.toIso8601String(),
                  subscriptionStatus:
                      m.status == 1 ? 'active' : 'expired',
                  isGuest: m.isGuest,
                ))
            .toList();

        final shouldUpdateMembers =
            state.searchQuery.isEmpty &&
            (state.selectedFilter == MemberFilter.all ||
             state.selectedFilter == MemberFilter.expiringSoon);

        state = state.copyWith(
          allMembers: models,
          members: shouldUpdateMembers ? models : null,
        );
      }
    });
  }

  // تحميل أول صفحة (أو إعادة التحميل بعد البحث / الفلترة / الترتيب / الإضافة)
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearCursor: true, error: null);
    try {
      final response = await _apiService.getMembers(
        search: state.searchQuery,
        cursor: null,
        filter: state.selectedFilter.apiValue,
        sortBy: state.selectedSort.apiValue,
      );

      if (!mounted) return;

      final nonGuestItems = response.items.where((m) => !m.isGuest).toList();
      state = state.copyWith(
        members: response.items,
        allMembers: (state.searchQuery.isEmpty && state.selectedFilter == MemberFilter.all)
            ? nonGuestItems
            : (state.allMembers.isEmpty ? nonGuestItems : state.allMembers),
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final response = await _apiService.getMembers(
        search: state.searchQuery,
        cursor: state.nextCursor,
        filter: state.selectedFilter.apiValue,
        sortBy: state.selectedSort.apiValue,
      );

      if (!mounted) return;

      state = state.copyWith(
        members: [...state.members, ...response.items],
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setFilter(MemberFilter filter) {
    if (state.selectedFilter == filter) return;
    state = state.copyWith(selectedFilter: filter);
    loadInitial();
  }

  void setSort(MemberSortOption sort) {
    if (state.selectedSort == sort) return;
    HapticFeedback.selectionClick();
    state = state.copyWith(selectedSort: sort);
    loadInitial();
  }

  // البحث مع Debounce (400ms) لحماية السيرفر من الطلبات المتتالية
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (state.searchQuery != query.trim()) {
        state = state.copyWith(searchQuery: query.trim());
        loadInitial();
      }
    });
  }

  /// Resets the status filter to [MemberFilter.all] and clears the search query string.
  void resetFilters() {
    _debounceTimer?.cancel();
    state = state.copyWith(
      selectedFilter: MemberFilter.all,
      searchQuery: '',
    );
    loadInitial();
  }

  // إضافة مشترك جديد وتحديث القائمة
  Future<void> addMember({
    required String fullName,
    required String phoneNumber,
    String? planId,
    int? method,
    double? amountPaid,
  }) async {
    await _apiService.createMember(
      fullName: fullName,
      phoneNumber: phoneNumber,
      planId: planId,
      method: method,
      amountPaid: amountPaid,
    );
    await loadInitial();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _membersSubscription?.cancel();
    super.dispose();
  }
}

// 4. الـ Provider العام للمشتركين
final membersProvider =
    StateNotifierProvider<MembersNotifier, MembersState>((ref) {
  final apiService = ref.watch(gymApiServiceProvider);
  final membersDao = ref.watch(membersDaoProvider);
  return MembersNotifier(apiService, membersDao);
});

// StreamProvider exposing real-time non-guest members directly from Drift
final localMembersProvider = StreamProvider<List<MemberModel>>((ref) {
  final dao = ref.watch(membersDaoProvider);
  return dao.watchAllMembers().map((list) => list
      .where((m) => !m.isGuest)
      .map((m) => MemberModel(
            id: m.id,
            fullName: m.fullName,
            phoneNumber: m.phone,
            photoUrl: m.photoUrl,
            activePlanName: m.planName,
            subscriptionEndDate: m.subscriptionEndDate?.toIso8601String(),
            subscriptionStatus: m.status == 1 ? 'active' : 'expired',
            isGuest: m.isGuest,
          ))
      .toList());
});

/// Lightweight Riverpod provider fetching GET /api/members/summary
/// falling back to local Drift computation if offline/error.
final membersSummaryProvider =
    FutureProvider.autoDispose<MembersSummaryData>((ref) async {
  final apiService = ref.watch(gymApiServiceProvider);
  return apiService.getMembersSummary();
});
