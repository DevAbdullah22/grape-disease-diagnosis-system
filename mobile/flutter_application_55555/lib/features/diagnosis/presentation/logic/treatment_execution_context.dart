import 'package:flutter_application_55555/core/models/recommendation.dart';

/// A value object encapsulating all derived information needed by the
/// recommendations screen.  Previously this logic lived inside the
/// screen widget, which caused the UI to compute a large amount of
/// execution-related state.  Moving it here keeps the screen focused on
/// display and interaction only.

class TreatmentExecutionContext {
  final List<TreatmentStep> steps;
  final List<TreatmentExecution> executions;
  final Set<int> executedSet;

  // derived counts & flags
  final int totalSteps;
  final int completedSteps;
  final bool hasSteps;
  final int safeIndex;
  final TreatmentStep? currentStep;
  final int? currentOrder;
  final int? nextStepOrder;
  final DateTime? currentNextDose;
  final DateTime? currentExecutedAt;
  final bool nextDue;
  final bool alreadyExecuted;
  final bool isCurrentStep;
  final bool canExecute;
  final bool isActionLoading;
  final bool allCompleted;
  final String actionLabel;

  TreatmentExecutionContext._({
    required this.steps,
    required this.executions,
    required this.executedSet,
    required this.totalSteps,
    required this.completedSteps,
    required this.hasSteps,
    required this.safeIndex,
    required this.currentStep,
    required this.currentOrder,
    required this.nextStepOrder,
    required this.currentNextDose,
    required this.currentExecutedAt,
    required this.nextDue,
    required this.alreadyExecuted,
    required this.isCurrentStep,
    required this.canExecute,
    required this.isActionLoading,
    required this.allCompleted,
    required this.actionLabel,
  });

  /// Factory that computes all values based on the current recommendation
  /// and transient execution state.
  factory TreatmentExecutionContext.fromModel(
    Recommendation recommendation, {
    required int currentStepIndex,
    required Set<int> executingSteps,
    required bool executingNext,
  }) {
    final steps = recommendation.steps ?? <TreatmentStep>[];
    final executions = recommendation.executions ?? <TreatmentExecution>[];
    final executedSet = _executedSetFor(recommendation);

    final totalSteps = steps.length;
    final completedSteps = steps
        .where((step) => step.stepOrder != null && executedSet.contains(step.stepOrder))
        .length;
    final hasSteps = totalSteps > 0;

    var safeIndex = currentStepIndex;
    if (safeIndex < 0) safeIndex = 0;
    if (hasSteps && safeIndex >= totalSteps) safeIndex = totalSteps - 1;

    final currentStep = hasSteps ? steps[safeIndex] : null;
    final currentOrder = currentStep?.stepOrder;

    int? nextStepOrder;
    for (final step in steps) {
      final order = step.stepOrder;
      if (order != null && !executedSet.contains(order)) {
        nextStepOrder = order;
        break;
      }
    }

    TreatmentExecution? executionForCurrent;
    if (currentOrder != null) {
      for (final exec in executions) {
        if (exec.doseNumber == currentOrder) {
          executionForCurrent = exec;
          break;
        }
      }
    }

    var currentNextDose = executionForCurrent?.nextDoseAt;
    final currentExecutedAt = executionForCurrent?.executedAt;

    if (currentNextDose == null && executions.isNotEmpty) {
      currentNextDose = executions.last.nextDoseAt;
    }

    var nextDue = true;
    if (currentNextDose != null) {
      final nowUtc = DateTime.now().toUtc();
      final targetUtc = currentNextDose.toUtc();
      nextDue = nowUtc.isAfter(targetUtc) || nowUtc.isAtSameMomentAs(targetUtc);
    }

    final alreadyExecuted =
        currentOrder != null && executedSet.contains(currentOrder);
    final isCurrentStep =
        !hasSteps || (currentOrder != null && currentOrder == nextStepOrder);
    final allCompleted = hasSteps && completedSteps == totalSteps;
    final isActionLoading = hasSteps
        ? (currentOrder != null && executingSteps.contains(currentOrder))
        : executingNext;

    final canExecute = hasSteps
        ? (!alreadyExecuted &&
            isCurrentStep &&
            nextDue &&
            currentOrder != null &&
            !executingSteps.contains(currentOrder))
        : !executingNext;

    String actionLabel;
    if (!hasSteps) {
      actionLabel = 'بدء تنفيذ العلاج';
    } else if (allCompleted) {
      actionLabel = 'اكتملت الخطة';
    } else if (currentOrder == null) {
      actionLabel = 'تعذّر تحديد الجرعة';
    } else if (alreadyExecuted) {
      actionLabel = 'منفّذة';
    } else if (!isCurrentStep) {
      actionLabel = 'ليست الجرعة الحالية';
    } else if (!nextDue) {
      actionLabel = 'موعد الجرعة لم يحن بعد';
    } else {
      actionLabel = 'تنفيذ الجرعة الآن';
    }

    return TreatmentExecutionContext._(
      steps: steps,
      executions: executions,
      executedSet: executedSet,
      totalSteps: totalSteps,
      completedSteps: completedSteps,
      hasSteps: hasSteps,
      safeIndex: safeIndex,
      currentStep: currentStep,
      currentOrder: currentOrder,
      nextStepOrder: nextStepOrder,
      currentNextDose: currentNextDose,
      currentExecutedAt: currentExecutedAt,
      nextDue: nextDue,
      alreadyExecuted: alreadyExecuted,
      isCurrentStep: isCurrentStep,
      canExecute: canExecute,
      isActionLoading: isActionLoading,
      allCompleted: allCompleted,
      actionLabel: actionLabel,
    );
  }

  /// convenience getters requested by the refactor requirements
  bool get isFullyExecuted => allCompleted;

  /// steps that have not yet been executed (ordered by step order)
  List<TreatmentStep> get remainingSteps =>
      steps.where((s) => s.stepOrder == null || !executedSet.contains(s.stepOrder))
          .toList();

  /// next step order that is not yet executed
  int? get nextExecutableStep => nextStepOrder;

  /// progress ratio 0..1
  double get executionProgress =>
      totalSteps == 0 ? 0 : completedSteps / totalSteps;

  /// determine the next index for UI when given the raw model
  static int nextStepIndex(Recommendation? model) {
    final steps = model?.steps ?? <TreatmentStep>[];
    if (steps.isEmpty) return 0;
    final executed = _executedSetFor(model);
    for (var i = 0; i < steps.length; i++) {
      final order = steps[i].stepOrder;
      if (order == null || !executed.contains(order)) {
        return i;
      }
    }
    return steps.length - 1;
  }

  static Set<int> _executedSetFor(Recommendation? model) {
    final executions = model?.executions ?? <TreatmentExecution>[];
    return executions
        .where((execution) => execution.doseNumber != null)
        .map((execution) => execution.doseNumber!)
        .toSet();
  }
}
