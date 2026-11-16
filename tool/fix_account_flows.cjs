const fs=require('node:fs');
function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
edit('lib/screens/profile/profile_screen.dart',s=>{
  s="import '../../widgets/common/account_dialogs.dart';\n"+s;
  s=s.replace("import 'package:flutter/services.dart';\n",'').replace("import 'package:url_launcher/url_launcher.dart';\n",'');
  const a=s.indexOf('  void _showChangePasswordDialog('), b=s.indexOf('  @override\n  Widget build',a);
  s=s.slice(0,a)+`  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final changed = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
    if (context.mounted && changed == true) AppSnackbar.showSuccess(context, 'Password updated.');
  }

  void _showHelpCenterDialog(BuildContext context) {
    final phone = context.read<BranchProvider>().selectedBranch?.phone;
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (_) => HelpCenterSheet(branchPhone: phone));
  }

`+s.slice(b);
  s=s.replace("subtitle: 'Saved debit cards, JazzCash & Easypaisa'", "subtitle: 'JazzCash & Easypaisa wallet references'");
  const history=s.indexOf("                  title: 'Token Activity History'");
  if(history>=0){
    const start=s.lastIndexOf('                Divider(',history);
    const end=s.indexOf('                ),',history)+19;
    s=s.slice(0,start)+s.slice(end);
  }
  return s;
});
fs.writeFileSync('lib/screens/auth/reset_password_screen.dart',`import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';

/// Password reset is completed through Firebase's verified email action link.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen();
}
`);
edit('lib/screens/auth/signup_screen.dart',s=>{
  s="import '../../routes/role_router.dart';\n"+s;
  return s.replace(/      if \(auth.isAdmin\) \{[\s\S]*?      \}/, '      RoleRouter.navigateHome(context, auth.currentUser);').replace(/ else \{\n        Navigator.of\(context\).pushNamedAndRemoveUntil\('\/home',[\s\S]*?      \}/,'');
});
edit('lib/models/admin/system_settings_model.dart',s=>s.replaceAll("'contact@foodfight.pk'","''").replaceAll("'+92 300 1234567'","''").replaceAll("'+923001234567'","''"));
edit('lib/screens/orders/order_tracking_screen.dart',s=>s.replace('final timestamp = _formatStepTime(order.createdAt, index);',`final recorded = order.statusHistory.where((event) => event.status == step['status']).firstOrNull;
                          final timestamp = recorded != null ? _formatStepTime(recorded.timestamp, index)
                              : index == 0 ? _formatStepTime(order.createdAt, 0) : '';`));
