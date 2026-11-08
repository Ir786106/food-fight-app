import '../constants/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

enum AppSnackbarType { success, error, info, warning }

/// Scaffold reserves its navigation/action bar and keyboard space. Adding that
/// height here again would leave a floating gap above the content.
class AppSnackbar {
  AppSnackbar._();

  static void showSuccess(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context,
          message: message, type: AppSnackbarType.success, action: action);

  static void showError(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context,
          message: message, type: AppSnackbarType.error, action: action);

  static void showInfo(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context, message: message, action: action);

  static void show(BuildContext context,
      {required String message,
      AppSnackbarType type = AppSnackbarType.info,
      SnackBarAction? action}) {
    _present(context, content: Text(message), type: type, action: action);
  }

  /// Rich feedback uses the same style and inset policy. Actions are preserved;
  /// per-screen margins and durations are discarded.
  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    final color = snackBar.backgroundColor;
    final type = color == AppColors.error || color == Colors.red
        ? AppSnackbarType.error
        : color == AppColors.success || color == Colors.green
            ? AppSnackbarType.success
            : AppSnackbarType.info;
    final content = snackBar.content;
    _present(context,
        content: content is Text && content.data != null
            ? Text(content.data!)
            : content,
        type: type,
        action: snackBar.action);
  }

  static void _present(BuildContext context,
      {required Widget content,
      required AppSnackbarType type,
      SnackBarAction? action}) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (type) {
      AppSnackbarType.success => AppColors.feedbackSuccess,
      AppSnackbarType.error => scheme.error,
      AppSnackbarType.warning => AppColors.feedbackWarning,
      AppSnackbarType.info => scheme.inverseSurface,
    };
    final foreground =
        type == AppSnackbarType.info ? scheme.onInverseSurface : Colors.white;
    final icon = switch (type) {
      AppSnackbarType.success => Icons.check_circle_outline,
      AppSnackbarType.error => Icons.error_outline,
      AppSnackbarType.warning => Icons.warning_amber_rounded,
      AppSnackbarType.info => Icons.info_outline,
    };
    if (type == AppSnackbarType.success) HapticFeedback.lightImpact();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, size: AppDimens.iconSizeSmall, color: foreground),
        const SizedBox(width: AppDimens.space8),
        Expanded(
            child: DefaultTextStyle(
          style: TextStyle(color: foreground, fontSize: 14, height: 1.3),
          child: content,
        )),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: type == AppSnackbarType.error ? 4 : 3),
      margin: const EdgeInsets.fromLTRB(AppDimens.space16, AppDimens.space8,
          AppDimens.space16, AppDimens.space12),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16, vertical: AppDimens.space12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius12)),
      action: action == null
          ? null
          : SnackBarAction(
              label: action.label,
              onPressed: action.onPressed,
              textColor: foreground),
    ));
  }
}
