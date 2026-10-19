import 'dart:async';

import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/question.dart';
import '../../../data/models/result.dart';
import '../../../data/repositories/assessment_repository.dart';
import '../../../services/progress_reporter.dart';
import 'attempt_store.dart';

typedef Clock = DateTime Function();
typedef AssessmentFinished =
    void Function(AssessmentResult result, AssessmentKind kind);

/// One engine for quizzes, homework and exams.
class AssessmentPlayerController extends BaseController {
  AssessmentPlayerController(
    this._repository,
    this._store,
    this.assessmentId, {
    this.clock = DateTime.now,
    this.periodicTimer = Timer.periodic,
    AssessmentFinished? onFinished,
    void Function(String message)? showMessage,
  }) : _onFinished = onFinished ?? _openResult,
       _showMessage = showMessage ?? ((message) => Get.snackbar('', message));

  static const _retryEvery = 5;

  final AssessmentRepository _repository;
  final AttemptStore _store;
  final int assessmentId;
  final Clock clock;
  final PeriodicTimer periodicTimer;
  final AssessmentFinished _onFinished;
  final void Function(String message) _showMessage;

  final attempt = Rxn<Attempt>();
  final index = 0.obs;
  final answers = <int, int>{}.obs;
  final pendingAnswers = <int, int>{}.obs;
  final flagged = <int>{}.obs;
  final remaining = Rxn<Duration>();
  final submitting = false.obs;

  /// Server clock minus phone clock, so a wrong phone clock cannot move the deadline.
  Duration _serverOffset = Duration.zero;
  Timer? _ticker;
  int _ticks = 0;
  bool _finished = false;
  Future<void>? _flushing;

  Question? get question {
    final questions = attempt.value?.questions ?? const <Question>[];
    return index.value < questions.length ? questions[index.value] : null;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  Future<void> load() => run(() async {
    final next = await _repository.start(assessmentId);
    // The offset is fixed when the attempt is first seen: on resume `started_at`
    // is old and no longer tells the server's current time.
    _serverOffset =
        _store.serverOffset(next.id) ?? next.startedAt.difference(clock());
    _store.saveServerOffset(next.id, _serverOffset);
    pendingAnswers.assignAll(_store.pending(next.id));
    answers.assignAll({...next.answers, ...pendingAnswers});
    attempt.value = next;
    _ticker ??= periodicTimer(const Duration(seconds: 1), (_) => tick());
    tick();
    unawaited(retryPending());
  });

  void tick() {
    final deadline = attempt.value?.deadlineAt;
    if (deadline != null) {
      final left = deadline.difference(clock().add(_serverOffset));
      remaining.value = left.isNegative ? Duration.zero : left;
      if (left <= Duration.zero) {
        unawaited(submit(timeUp: true));
        return;
      }
    }
    if (++_ticks % _retryEvery == 0) unawaited(retryPending());
  }

  void select(int questionId, int optionId) {
    final current = attempt.value;
    if (current == null || _finished) return;
    answers[questionId] = optionId;
    pendingAnswers[questionId] = optionId;
    _store.savePending(current.id, pendingAnswers);
    unawaited(retryPending());
  }

  void goTo(int value) {
    final count = attempt.value?.questions.length ?? 0;
    if (value >= 0 && value < count) index.value = value;
  }

  void toggleFlag(int questionId) => flagged.contains(questionId)
      ? flagged.remove(questionId)
      : flagged.add(questionId);

  /// Sends queued answers in order; stops at the first network failure and
  /// keeps the rest for the next tick.
  Future<void> retryPending() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<void> _flush() async {
    final attemptId = attempt.value?.id;
    if (attemptId == null) return;
    while (pendingAnswers.isNotEmpty) {
      final MapEntry(key: questionId, value: optionId) =
          pendingAnswers.entries.first;
      try {
        await _repository.answer(attemptId, questionId, optionId);
      } on ApiException catch (exception) {
        // A 4xx will never succeed (attempt closed, question gone): drop it.
        final rejected =
            exception.statusCode >= 400 &&
            exception.statusCode < 500 &&
            exception.statusCode != 429;
        if (!rejected) return;
      } catch (_) {
        return;
      }
      if (pendingAnswers[questionId] == optionId) {
        pendingAnswers.remove(questionId);
      }
      _store.savePending(attemptId, pendingAnswers);
    }
  }

  Future<void> submit({bool timeUp = false}) async {
    final current = attempt.value;
    if (current == null || submitting.value || _finished) return;
    submitting.value = true;
    try {
      await retryPending();
      if (pendingAnswers.isNotEmpty && !timeUp) {
        _showMessage('errors.network'.tr);
        return;
      }
      AssessmentResult result;
      try {
        result = await _repository.submit(current.id);
      } on ApiException catch (exception) {
        // The server auto-submits at the deadline.
        if (exception.code != 'already_submitted') rethrow;
        result = await _repository.result(current.id);
      }
      _finished = true;
      _ticker?.cancel();
      _store.clear(current.id);
      _onFinished(result, current.kind);
    } on ApiException catch (exception) {
      if (!timeUp) _showMessage(exception.message);
    } catch (_) {
      if (!timeUp) _showMessage('errors.generic'.tr);
    } finally {
      submitting.value = false;
    }
  }

  static void _openResult(AssessmentResult result, AssessmentKind kind) =>
      Get.offNamed(
        AppRoutes.assessmentResult,
        arguments: {
          'attemptId': result.attemptId,
          'kind': kind,
          'result': result,
        },
      );
}
