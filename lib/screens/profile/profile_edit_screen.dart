import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _altMobile;
  late final TextEditingController _gender;
  late final TextEditingController _dob;

  // Address fields
  late final TextEditingController _homeStreet;
  late final TextEditingController _homeCity;
  late final TextEditingController _homePincode;
  late final TextEditingController _homeState;
  late final TextEditingController _bizStreet;
  late final TextEditingController _bizCity;
  late final TextEditingController _bizPincode;
  late final TextEditingController _bizState;

  @override
  void initState() {
    super.initState();
    final v = context.read<AuthProvider>().vendor;
    _name      = TextEditingController(text: v?.name ?? '');
    _email     = TextEditingController(text: v?.email ?? '');
    _altMobile = TextEditingController(text: v?.alternativeMobile ?? '');
    _gender    = TextEditingController(text: v?.gender ?? '');
    _dob       = TextEditingController(text: v?.dob ?? '');
    _homeStreet  = TextEditingController(text: v?.homeAddress.street ?? '');
    _homeCity    = TextEditingController(text: v?.homeAddress.city ?? '');
    _homePincode = TextEditingController(text: v?.homeAddress.pincode ?? '');
    _homeState   = TextEditingController(text: v?.homeAddress.state ?? '');
    _bizStreet   = TextEditingController(text: v?.businessAddress.street ?? '');
    _bizCity     = TextEditingController(text: v?.businessAddress.city ?? '');
    _bizPincode  = TextEditingController(text: v?.businessAddress.pincode ?? '');
    _bizState    = TextEditingController(text: v?.businessAddress.state ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _altMobile, _gender, _dob,
        _homeStreet, _homeCity, _homePincode, _homeState,
        _bizStreet, _bizCity, _bizPincode, _bizState]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    setState(() => _loading = true);
    try {
      // Update profile
      final profileRes = await http.patch(
        Uri.parse(ApiConstants.profile),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'alternativeMobile': _altMobile.text.trim().isNotEmpty
              ? int.tryParse(_altMobile.text.trim()) : null,
          'gender': _gender.text.trim(),
          'dob': _dob.text.trim(),
        }),
      );

      // Update address
      await http.patch(
        Uri.parse(ApiConstants.address),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'homeAddress': {
            'street': _homeStreet.text.trim(),
            'city': _homeCity.text.trim(),
            'pincode': _homePincode.text.trim(),
            'state': _homeState.text.trim(),
          },
          'businessAddress': {
            'street': _bizStreet.text.trim(),
            'city': _bizCity.text.trim(),
            'pincode': _bizPincode.text.trim(),
            'state': _bizState.text.trim(),
          },
        }),
      );

      final body = jsonDecode(profileRes.body);
      if (!mounted) return;
      if (body['status'] == true) {
        await auth.getProfile();
        if (!mounted) return;
        _snack('Profile updated successfully', AppColors.statusCompleted);
        Navigator.of(context).pop();
      } else {
        _snack(body['msg'] ?? 'Failed to update profile', AppColors.error);
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _section('Personal Info'),
            _field(_name, 'Full Name', Icons.person_outline, required: true),
            _field(_email, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
            _field(_altMobile, 'Alternate Mobile', Icons.phone_outlined, keyboard: TextInputType.phone),
            _field(_gender, 'Gender', Icons.wc_outlined, hint: 'Male / Female / Other'),
            _field(_dob, 'Date of Birth', Icons.cake_outlined, hint: 'DD/MM/YYYY'),

            const SizedBox(height: 24),
            _section('Home Address', required: true),
            _field(_homeStreet, 'Street / Area', Icons.location_on_outlined),
            _field(_homeCity, 'City', Icons.location_city_outlined),
            _field(_homePincode, 'Pincode', Icons.pin_drop_outlined, keyboard: TextInputType.number),
            _field(_homeState, 'State', Icons.map_outlined),

            const SizedBox(height: 24),
            _section('Business Address', subtitle: '(Optional)'),
            _field(_bizStreet, 'Street / Area', Icons.location_on_outlined),
            _field(_bizCity, 'City', Icons.location_city_outlined),
            _field(_bizPincode, 'Pincode', Icons.pin_drop_outlined, keyboard: TextInputType.number),
            _field(_bizState, 'State', Icons.map_outlined),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, {bool required = false, String? subtitle}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (required)
          const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ],
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    String? hint,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
        ),
      );
}
