import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Exports the visible admin dataset using the platform share/download flow.
Future<void> shareAdminCsv(
  BuildContext context, {
  required String filename,
  required List<List<dynamic>> rows,
}) async {
  final sanitized = rows
      .map((row) => row.map((value) {
            if (value is String &&
                RegExp(r'^[=+@-]').hasMatch(value.trimLeft())) {
              return "'$value";
            }
            return value;
          }).toList())
      .toList();
  final csv = const ListToCsvConverter().convert(sanitized);
  final box = context.findRenderObject();
  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(Uint8List.fromList(utf8.encode(csv)),
          mimeType: 'text/csv'),
    ],
    fileNameOverrides: [filename],
    sharePositionOrigin: box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null,
  ));
}
