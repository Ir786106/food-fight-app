import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../providers/auth_provider.dart';

class MenuReportsScreen extends StatelessWidget {
  const MenuReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('menuReports');
    if (user?.isSuperAdmin != true) query = query.where('branchId', isEqualTo: user?.branchId ?? '');
    return Scaffold(appBar: AppBar(title: const Text('Menu issue reports')),
      body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: query.snapshots(), builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Could not load reports. Check your connection and permissions.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reports = snapshot.data!.docs.toList()..sort((a,b) {
          final first = a.data()['createdAt'], second = b.data()['createdAt'];
          return (second is Timestamp ? second.millisecondsSinceEpoch : 0).compareTo(first is Timestamp ? first.millisecondsSinceEpoch : 0);
        });
        if (reports.isEmpty) return const Center(child: Text('No menu issues reported.'));
        return ListView.separated(padding: const EdgeInsets.all(AppDimens.space16), itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space8), itemBuilder: (context, index) {
            final doc = reports[index], data = doc.data();
            final resolved = data['status'] == 'resolved';
            return Card(child: Padding(padding: const EdgeInsets.all(AppDimens.space16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['menuItemName']?.toString() ?? 'Item ${data['menuItemId']}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimens.space8), Text(data['message']?.toString() ?? ''),
                TextButton.icon(icon: Icon(resolved ? Icons.refresh : Icons.check), label: Text(resolved ? 'Reopen' : 'Resolve'),
                  onPressed: () async {
                    try { await doc.reference.update({'status': resolved ? 'open' : 'resolved', 'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': user?.id}); }
                    catch (_) { if (context.mounted) AppSnackbar.showError(context, 'Could not update report. Retry.'); }
                  }),
              ])));
          });
      }));
  }
}
