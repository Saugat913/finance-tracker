import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

class WorkViewModel extends ChangeNotifier {
  WorkViewModel({
    required this.financeStore,
    required this.jobRepo,
    required this.shiftRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
    _startTimer();
  }

  final FinanceStore financeStore;
  final JobRepository jobRepo;
  final ShiftRepository shiftRepo;

  Timer? _ticker;
  int? _selectedJobId;
  int? get selectedJobId => _selectedJobId;

  void _onStoreChanged() {
    notifyListeners();
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (activeShift != null) {
        notifyListeners();
      }
    });
  }

  List<Job> get jobs => financeStore.jobs;
  List<Shift> get shifts => financeStore.shifts;
  String get baseCurrency => financeStore.baseCurrency;

  Map<int, Job> get jobsById => {for (final j in jobs) j.id: j};

  Job? get selectedJob {
    if (jobs.isEmpty) return null;
    if (_selectedJobId != null) {
      return jobsById[_selectedJobId] ?? jobs.first;
    }
    return jobs.first;
  }

  void selectJob(int id) {
    _selectedJobId = id;
    notifyListeners();
  }

  Shift? get activeShift {
    for (final s in shifts) {
      if (s.status == ShiftStatus.inProgress.value) return s;
    }
    return null;
  }

  Duration get activeShiftElapsed {
    final shift = activeShift;
    if (shift == null) return Duration.zero;
    final start = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
    return DateTime.now().difference(start);
  }

  ShiftEarnings? get activeShiftLiveEarnings {
    final shift = activeShift;
    if (shift == null) return null;
    final job = jobsById[shift.jobId];
    if (job == null) return null;

    final rate = shift.rateOverrideMinor ?? job.hourlyRateMinor;
    final elapsedMinutes = activeShiftElapsed.inMinutes;
    final earnings = (rate * elapsedMinutes / 60).round();

    return ShiftEarnings(
      workedMinutes: elapsedMinutes,
      earningsMinor: earnings,
      hourlyRateMinor: rate,
    );
  }

  double get hoursThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final jById = jobsById;
    var totalMin = 0;

    for (final s in shifts) {
      if (s.status != ShiftStatus.completed.value || s.endAt == null) continue;
      final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
      if (!start.isBefore(weekStart)) {
        final job = jById[s.jobId];
        if (job != null) {
          final earnings = ShiftEarnings.forShift(s, job);
          totalMin += earnings.workedMinutes;
        }
      }
    }
    return totalMin / 60;
  }

  int get shiftsLeftThisWeek {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    var count = 0;

    for (final s in shifts) {
      if (s.status == ShiftStatus.scheduled.value) {
        final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
        if (start.isAfter(now) && !start.isAfter(weekEnd)) {
          count++;
        }
      }
    }
    return count;
  }

  Future<int> addJob({
    required String name,
    required int hourlyRateMinor,
    String? employer,
    String? currencyCode,
    int colorIndex = 0,
  }) async {
    final id = await jobRepo.add(
      name: name,
      hourlyRateMinor: hourlyRateMinor,
      employer: employer,
      currencyCode: currencyCode ?? baseCurrency,
      colorIndex: colorIndex,
    );
    TelemetryService.instance.trackEvent('job_added', {'name': name});
    return id;
  }

  Future<int> scheduleShift({
    required int jobId,
    required DateTime startAt,
    DateTime? endAt,
    int breakMinutes = 0,
    String? note,
  }) async {
    final id = await shiftRepo.add(
      jobId: jobId,
      startAt: startAt,
      endAt: endAt,
      breakMinutes: breakMinutes,
      status: ShiftStatus.scheduled,
      note: note,
    );
    TelemetryService.instance.trackEvent('shift_scheduled', {'jobId': jobId});
    return id;
  }

  Future<int> startShift({required int jobId, DateTime? startAt}) async {
    final id = await shiftRepo.add(
      jobId: jobId,
      startAt: startAt ?? DateTime.now(),
      breakMinutes: 0,
      status: ShiftStatus.inProgress,
    );
    TelemetryService.instance.trackEvent('shift_started', {'jobId': jobId});
    return id;
  }

  Future<ShiftEarnings> endShift(int shiftId, {int breakMinutes = 0, DateTime? endAt}) async {
    final endTime = endAt ?? DateTime.now();
    await shiftRepo.finish(shiftId, breakMinutes: breakMinutes, endAt: endTime);

    final shift = shifts.firstWhere((s) => s.id == shiftId, orElse: () => shifts.first);
    final job = jobsById[shift.jobId] ?? jobs.first;
    final completedShift = Shift(
      id: shift.id,
      jobId: shift.jobId,
      startAt: shift.startAt,
      endAt: endTime.millisecondsSinceEpoch,
      breakMinutes: breakMinutes,
      status: ShiftStatus.completed.value,
      note: shift.note,
      rateOverrideMinor: shift.rateOverrideMinor,
      createdAt: shift.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final earnings = ShiftEarnings.forShift(completedShift, job);
    TelemetryService.instance.trackEvent('shift_ended', {
      'jobId': shift.jobId,
      'workedMinutes': earnings.workedMinutes,
      'earningsMinor': earnings.earningsMinor,
    });
    return earnings;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
