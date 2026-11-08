import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/utils/app_snackbar.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../widgets/custom_button.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? address;
  const AddAddressScreen({super.key, this.address});
  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _details;
  String _type = 'home';
  bool _default = false;
  bool _saving = false;
  bool _locating = false;
  LatLng? _point;
  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _label = TextEditingController(text: a?.label ?? 'Home');
    _details = TextEditingController(text: a?.details ?? '');
    _type = a?.iconType ?? 'home';
    _default = a?.isDefault ?? false;
    if (a?.latitude != null && a?.longitude != null) _point = LatLng(a!.latitude!, a.longitude!);
  }
  @override
  void dispose() { _label.dispose(); _details.dispose(); super.dispose(); }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on location services, then retry.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        if (mounted) { AppSnackbar.showInfo(context, 'Enable location permission in app settings.',
          action: const SnackBarAction(label: 'Settings', onPressed: Geolocator.openAppSettings)); }
        return;
      }
      if (permission == LocationPermission.denied) throw StateError('Location permission was declined. You can enter an address manually.');
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 20)));
      if (mounted) setState(() => _point = LatLng(position.latitude, position.longitude));
    } catch (_) {
      if (mounted) AppSnackbar.showError(context, 'Could not locate you. Check GPS and permission, or enter your address manually.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _map() async {
    final branch = context.read<BranchProvider>().selectedBranch;
    final initial = _point ?? (branch?.hasCoordinates == true ? LatLng(branch!.latitude!, branch.longitude!) : null);
    if (initial == null) { await _locate(); return; }
    var picked = initial;
    if (!mounted) return;
    final result = await Navigator.of(context).push<LatLng>(MaterialPageRoute(builder: (context) => StatefulBuilder(
      builder: (context, update) => Scaffold(
        appBar: AppBar(title: const Text('Choose delivery location')),
        body: GoogleMap(initialCameraPosition: CameraPosition(target: initial, zoom: 15),
          onTap: (point) => update(() => picked = point),
          markers: {Marker(markerId: const MarkerId('delivery'), position: picked, draggable: true,
            onDragEnd: (point) => update(() => picked = point))}),
        bottomNavigationBar: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(AppDimens.space16),
          child: FilledButton(onPressed: () => Navigator.pop(context, picked), child: const Text('Use this location')))),
      ))));
    if (mounted && result != null) setState(() => _point = result);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) { AppSnackbar.showError(context, 'Sign in to save an address.'); return; }
    final branch = context.read<BranchProvider>().selectedBranch;
    if (_point != null && branch?.hasCoordinates == true && !branch!.isWithinDeliveryRadius(_point!.latitude, _point!.longitude)) {
      AppSnackbar.showError(context, 'This location is outside the selected branch’s delivery area. Choose a closer location or another branch.');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final address = AddressModel(id: widget.address?.id ?? '', userId: uid, label: _label.text.trim(), details: _details.text.trim(),
      iconType: _type, latitude: _point?.latitude, longitude: _point?.longitude, isDefault: _default,
      createdAt: widget.address?.createdAt ?? now, updatedAt: now);
    final provider = context.read<AddressProvider>();
    final AddressModel? saved;
    if (widget.address == null) { saved = await provider.addAddress(address); }
    else { saved = await provider.updateAddress(address) ? address : null; }
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved != null) { Navigator.pop(context, saved); }
    else { AppSnackbar.showError(context, 'Could not save the address. Check your connection and retry.'); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.address == null ? 'Add address' : 'Edit address')),
    body: SafeArea(bottom: false, child: Form(key: _form, child: ListView(
      padding: const EdgeInsets.all(AppDimens.space16), keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Wrap(spacing: AppDimens.space8, children: ['home','work','other'].map((type) => ChoiceChip(
          label: Text(type[0].toUpperCase() + type.substring(1)), selected: _type == type,
          onSelected: (_) => setState(() => _type = type))).toList()),
        const SizedBox(height: AppDimens.space16),
        TextFormField(controller: _label, maxLength: 40, decoration: const InputDecoration(labelText: 'Label'),
          validator: (value) => (value?.trim().length ?? 0) < 2 ? 'Enter a label' : null),
        const SizedBox(height: AppDimens.space16),
        TextFormField(controller: _details, minLines: 2, maxLines: 4, maxLength: 300,
          decoration: const InputDecoration(labelText: 'House, street, area and city'),
          validator: (value) => (value?.trim().length ?? 0) < 8 ? 'Enter a complete delivery address' : null),
        const SizedBox(height: AppDimens.space16),
        Wrap(spacing: AppDimens.space8, children: [
          OutlinedButton.icon(onPressed: _locating ? null : _locate, icon: const Icon(Icons.my_location), label: Text(_locating ? 'Locating…' : 'Use my location')),
          OutlinedButton.icon(onPressed: _map, icon: const Icon(Icons.map_outlined), label: const Text('Choose on map')),
        ]),
        if (_point != null) Text('Location selected: ${_point!.latitude.toStringAsFixed(5)}, ${_point!.longitude.toStringAsFixed(5)}'),
        const SizedBox(height: AppDimens.space16),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Default delivery address'), value: _default,
          onChanged: (value) => setState(() => _default = value)),
        const Text('Delivery availability and fees are checked again at checkout.'),
      ]))),
    bottomNavigationBar: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(AppDimens.space16),
      child: CustomButton(text: 'Save address', isLoading: _saving, onPressed: _saving ? null : _save))),
  );
}
