const fs=require('node:fs');
function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
edit('lib/screens/profile/edit_profile_screen.dart',s=>{
  s=s.replace("import 'dart:io';","import 'dart:typed_data';").replace("import '../../core/constants/image_storage.dart';\n",'');
  s=s.replace('  XFile? _pickedImage;', '  XFile? _pickedImage;\n  Uint8List? _pickedBytes;');
  s=s.replaceAll('if (img != null) {\n                    setState', 'if (img != null && mounted) {\n                    final bytes = await img.readAsBytes();\n                    if (!mounted) return;\n                    _pickedBytes = bytes;\n                    setState');
  s=s.replace('Image.file(\n                                      File(_pickedImage!.path),', 'Image.memory(\n                                      _pickedBytes!,');
  s=s.replace('path: StoragePaths.userImagesPath,', "path: 'profiles/' + user.id,");
  s=s.replace('  Future<void> _save() async {', `  Future<void> _save() async {
    if (_isLoading) return;
    if (_nameController.text.trim().length < 2) {
      AppSnackbar.showError(context, 'Enter your full name.'); return;
    }
    if (!RegExp(r'^(03\\d{9}|\\+923\\d{9})$').hasMatch(_phoneController.text.replaceAll(RegExp(r'[\\s()-]'), ''))) {
      AppSnackbar.showError(context, 'Enter a valid Pakistani mobile number.'); return;
    }`);
  return s;
});
edit('lib/screens/admin/orders/order_detail_modal.dart',s=>{
  s=s.replace('provider.activeRiders', 'provider.onlineRiders');
  s=s.replace('riderPhone: rider.phone,','riderPhone: rider.phone,\n                                      expectedRiderId: widget.order.riderId,');
  return s;
});
