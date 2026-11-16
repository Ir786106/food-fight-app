import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

String adminAccountUpdateError(Object error) {
  const unavailable =
      'Account changes require the Food Fight backend. Contact the platform owner to enable it.';
  if (error is MissingPluginException || error is UnimplementedError) {
    return unavailable;
  }
  if (error is FirebaseFunctionsException) {
    switch ((error.code, error.message)) {
      case ('not-found', 'Staff profile not found.'):
        return 'This staff profile could not be found. Refresh the account list.';
      case ('not-found', 'The selected branch no longer exists.'):
        return 'The selected branch no longer exists. Refresh and select another branch.';
      case (
          'failed-precondition',
          'Another Super Admin must manage this account.'
        ):
        return 'Ask another Super Admin to edit your account.';
      case (
          'failed-precondition',
          'This legacy profile has no Auth login. Provision a new account first.'
        ):
        return 'This staff profile has no Firebase sign-in account. Ask support to verify its identity.';
      case ('not-found', _):
        return unavailable;
      case ('resource-exhausted', _):
        return 'Too many account requests. Wait a minute and try again.';
    }
  }
  return platformOperationError(error,
      fallback: 'Unable to update the admin account. Please try again.');
}

String platformOperationError(Object error, {required String fallback}) {
  if (error is FirebaseFunctionsException && error.code == 'not-found') {
    return 'The platform service or requested record is unavailable. Try again or contact support.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Your account does not have permission for this action.',
      'unauthenticated' => 'Your session has expired. Sign in and try again.',
      'unavailable' ||
      'deadline-exceeded' =>
        'The server could not be reached. Check your connection and try again.',
      _ => fallback,
    };
  }
  return fallback;
}
