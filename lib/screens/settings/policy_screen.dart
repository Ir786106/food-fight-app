import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

class PolicyScreen extends StatelessWidget {
  final String title;
  final String field;
  const PolicyScreen({super.key, required this.title, required this.field});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('settings').doc('global_settings').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const ErrorView(message: 'Unable to load this document. Please try again.');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final text = snapshot.data?.data()?[field]?.toString().trim() ?? '';
        return SingleChildScrollView(padding: DesignSystem.screenPadding,
          child: SelectableText(text.isEmpty ? 'This document has not been published by the restaurant yet.' : text,
            style: Theme.of(context).textTheme.bodyLarge));
      },
    )),
  );
}
