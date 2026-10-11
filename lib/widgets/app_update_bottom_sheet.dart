import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_update_provider.dart';

class AppUpdateBottomSheet extends StatelessWidget {
  const AppUpdateBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const AppUpdateBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prov = context.watch<AppUpdateProvider>();
    final release = prov.availableRelease;
    if (release == null) return const SizedBox.shrink();

    return PopScope(
      canPop: !prov.isForceUpdate,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1211) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44, height: 5,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: AppColors.brandYellow, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.system_update_rounded, color: AppColors.brandMaroon, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Update Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.brandMaroon)),
                        Text('Version ${release.versionName} is ready', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                      ])),
                    ]),
                    if (release.releaseNotes != null && release.releaseNotes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text("What's New", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: isDark ? Colors.white70 : AppColors.brandMaroon)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A1A19) : const Color(0xFFFFF8E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          release.releaseNotes!.trim().length > 600 ? '${release.releaseNotes!.trim().substring(0, 600)}...' : release.releaseNotes!.trim(),
                          style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.grey.shade700, height: 1.5),
                        ),
                      ),
                    ],
                    if (prov.isForceUpdate) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(prov.forceConfig?.message ?? 'This update is required to continue using the app.', style: const TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600))),
                        ]),
                      ),
                    ],
                    if (prov.isDownloading) ...[
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: prov.downloadProgress, backgroundColor: Colors.grey.withValues(alpha: 0.2), color: AppColors.brandYellow, minHeight: 10),
                        )),
                        const SizedBox(width: 10),
                        Text('${(prov.downloadProgress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      TextButton(onPressed: prov.cancelDownload, child: const Text('Cancel', style: TextStyle(color: Colors.red))),
                    ],
                    if (prov.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(prov.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              final url = Uri.parse('https://github.com/Ir786106/food-fight-app/releases/latest');
                              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                            child: const Text('Open Release Page →'),
                          ),
                        ]),
                      ),
                    ],
                    if (prov.installReady) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Row(children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Download verified. Tap Install to continue.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (!prov.isDownloading) ...[
                      if (prov.installReady)
                        SizedBox(width: double.infinity, child: ElevatedButton.icon(
                          icon: const Icon(Icons.install_mobile_rounded),
                          label: const Text('Install Now'),
                          onPressed: () async {
                            final success = await prov.installApk();
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Install failed. Please try manually.')));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        ))
                      else
                        SizedBox(width: double.infinity, child: ElevatedButton.icon(
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          onPressed: prov.startDownload,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandYellow, foregroundColor: AppColors.brandMaroon, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        )),
                      if (!prov.isForceUpdate) ...[
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: TextButton(
                          onPressed: () { prov.skipVersion(release.versionName); Navigator.pop(context); },
                          child: const Text('Later', style: TextStyle(color: Colors.grey)),
                        )),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
