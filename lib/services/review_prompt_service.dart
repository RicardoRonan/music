import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPromptService {
  ReviewPromptService(
    this._prefs, {
    InAppReview? inAppReview,
  }) : _inAppReview = inAppReview ?? InAppReview.instance;

  static const _opensKey = 'review_prompt_app_opens';
  static const _firstLaunchMsKey = 'review_prompt_first_launch_ms';
  static const _meaningfulActionsKey = 'review_prompt_meaningful_actions';
  static const _requestedKey = 'review_prompt_requested';

  static const minAppOpens = 3;
  static const minDaysSinceFirstLaunch = 3;
  static const minMeaningfulActions = 3;

  final SharedPreferences _prefs;
  final InAppReview _inAppReview;

  Future<void> onAppOpenAndMaybePrompt() async {
    final opens = _prefs.getInt(_opensKey) ?? 0;
    await _prefs.setInt(_opensKey, opens + 1);

    if (!_prefs.containsKey(_firstLaunchMsKey)) {
      await _prefs.setInt(
        _firstLaunchMsKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    await _maybeRequestReview();
  }

  Future<void> onMeaningfulActionAndMaybePrompt() async {
    final actions = _prefs.getInt(_meaningfulActionsKey) ?? 0;
    await _prefs.setInt(_meaningfulActionsKey, actions + 1);
    await _maybeRequestReview();
  }

  bool get hasRequestedReview => _prefs.getBool(_requestedKey) ?? false;

  Future<void> _maybeRequestReview() async {
    if (hasRequestedReview) return;

    final opens = _prefs.getInt(_opensKey) ?? 0;
    if (opens < minAppOpens) return;

    final firstLaunchMs = _prefs.getInt(_firstLaunchMsKey);
    if (firstLaunchMs == null) return;
    final firstLaunch = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
    if (daysSinceFirstLaunch < minDaysSinceFirstLaunch) return;

    final meaningfulActions = _prefs.getInt(_meaningfulActionsKey) ?? 0;
    if (meaningfulActions < minMeaningfulActions) return;

    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) return;
      await _inAppReview.requestReview();
      await _prefs.setBool(_requestedKey, true);
    } catch (_) {
      // Fail silently to avoid disrupting playback or navigation UX.
    }
  }
}
