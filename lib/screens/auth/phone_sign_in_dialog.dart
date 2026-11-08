import '../../core/localization/app_language.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, PhoneAuthProvider, UserCredential;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class PhoneSignInDialog extends StatefulWidget {
  const PhoneSignInDialog({super.key});

  static bool get isSupported => kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static String? pakistaniMobile(String input) {
    final number = input.trim().replaceAll(RegExp(r'[\s()-]'), '');
    final national = number.replaceFirst(RegExp(r'^(?:\+92|0092|92|0)'), '');
    return RegExp(r'^3\d{9}$').hasMatch(national) ? '+92$national' : null;
  }

  @override
  State<PhoneSignInDialog> createState() => _PhoneSignInDialogState();
}

class _PhoneSignInDialogState extends State<PhoneSignInDialog> {
  final _input = TextEditingController();
  Future<UserCredential> Function(String)? _confirm;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = PhoneSignInDialog.pakistaniMobile(_input.text);
    if (phone == null) {
      setState(() => _error = 'Enter a valid Pakistani mobile number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    var autoVerified = false;
    try {
      final auth = FirebaseAuth.instance;
      if (kIsWeb) {
        final result = await auth.signInWithPhoneNumber(phone);
        _confirm = result.confirm;
      } else {
        final challenge = Completer<Future<UserCredential> Function(String)>();
        unawaited(auth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (credential) {
            if (challenge.isCompleted) return;
            autoVerified = true;
            challenge.complete((_) => auth.signInWithCredential(credential));
          },
          verificationFailed: (error) {
            if (!challenge.isCompleted) challenge.completeError(error);
          },
          codeSent: (id, _) {
            if (challenge.isCompleted) return;
            challenge.complete((code) => auth.signInWithCredential(
                PhoneAuthProvider.credential(verificationId: id, smsCode: code)));
          },
          codeAutoRetrievalTimeout: (id) {
            if (challenge.isCompleted) return;
            challenge.complete((code) => auth.signInWithCredential(
                PhoneAuthProvider.credential(verificationId: id, smsCode: code)));
          },
        ).catchError((Object error, StackTrace stack) {
          if (!challenge.isCompleted) challenge.completeError(error, stack);
        }));
        _confirm = await challenge.future.timeout(const Duration(seconds: 70));
      }
      if (mounted) _input.clear();
    } on FirebaseAuthException catch (error) {
      _error = switch (error.code) {
        'too-many-requests' => 'Too many requests. Please wait before trying again.',
        'operation-not-allowed' => 'Phone sign-in is unavailable.',
        _ => 'Could not send a code. Check the number and try again.',
      };
    } catch (_) {
      _error = 'Could not send a code. Please try again.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && autoVerified && _confirm != null) await _verify(automatic: true);
  }

  Future<void> _verify({bool automatic = false}) async {
    final code = _input.text.trim();
    if (!automatic && !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the six-digit code.');
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await auth.signInWithPhone(_confirm!, code);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!success) _error = auth.errorMessage;
    });
    if (success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final sent = _confirm != null;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(sent ? context.tr('Verify your phone') : context.tr('Continue with phone')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sent
                  ? context.tr('Enter the code sent by SMS.')
                  : context.tr('Firebase will use your number to verify your sign-in and prevent abuse.')),
              const SizedBox(height: 12),
              TextField(
                controller: _input,
                enabled: !_busy,
                keyboardType: sent ? TextInputType.number : TextInputType.phone,
                autofillHints: [sent ? AutofillHints.oneTimeCode : AutofillHints.telephoneNumber],
                inputFormatters: sent ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)] : null,
                decoration: InputDecoration(
                  labelText: sent ? context.tr('SMS code') : context.tr('Mobile number'),
                  hintText: sent ? null : '03XX XXXXXXX',
                  errorText: _error == null ? null : context.tr(_error!),
                ),
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(context.tr('Cancel')),
          ),
          if (sent)
            TextButton(
              onPressed: _busy ? null : () => setState(() {
                _confirm = null;
                if (mounted) _input.clear();
                _error = null;
              }),
              child: Text(context.tr('Request new code')),
            ),
          FilledButton(
            onPressed: _busy ? null : sent ? () => _verify() : _send,
            child: Text(sent ? context.tr('Verify') : context.tr('Send code')),
          ),
        ],
      ),
    );
  }
}
