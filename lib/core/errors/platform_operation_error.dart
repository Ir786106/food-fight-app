import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

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
