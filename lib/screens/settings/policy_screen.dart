import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/localization/app_language.dart';
import '../../shared/repositories/settings_repository.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key, required this.title, required this.field});
  final String title;
  final String field;

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  late Stream<Map<String, dynamic>> _settings;

  @override
  void initState() {
    super.initState();
    _settings = SettingsRepository.watchPublicSettings();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          child: StreamBuilder<Map<String, dynamic>>(
            stream: _settings,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorView(
                  message: context.tr('Unable to load this document.'),
                  onRetry: () => setState(() {
                    _settings = SettingsRepository.watchPublicSettings();
                  }),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: DesignSystem.screenPadding,
                  child: ShimmerLoader(height: 144),
                );
              }
              final text =
                  snapshot.data?[widget.field]?.toString().trim() ?? '';
              return SingleChildScrollView(
                padding: DesignSystem.screenPadding,
                child: SelectableText(
                  text.isEmpty
                      ? context.tr('This document has not been published yet.')
                      : text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            },
          ),
        ),
      );
}
