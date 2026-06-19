import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  List<dynamic> _bankDetails = [];
  bool _approved = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _bankName      = TextEditingController();
  final _holderName    = TextEditingController();
  final _accountNumber = TextEditingController();
  final _ifsc          = TextEditingController();
  String _accountType  = 'Savings';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _bankName.dispose();
    _holderName.dispose();
    _accountNumber.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    final token = context.read<AuthProvider>().token ?? '';
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.bankDetails),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body);
      if (body['status'] == true) {
        setState(() {
          _bankDetails = body['data']['bankDetails'] ?? [];
          _approved    = body['data']['bankDetailsApproved'] == true;
        });
      } else {
        setState(() => _error = body['msg'] ?? 'Failed to load bank details');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().token ?? '';
    setState(() => _saving = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.bankDetails),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'bankName':      _bankName.text.trim(),
          'holderName':    _holderName.text.trim(),
          'accountNumber': int.parse(_accountNumber.text.trim()),
          'ifscCode':      _ifsc.text.trim().toUpperCase(),
          'accountType':   _accountType,
        }),
      );
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (body['status'] == true) {
        _bankName.clear(); _holderName.clear();
        _accountNumber.clear(); _ifsc.clear();
        _snack('Bank details saved', AppColors.statusCompleted);
        _fetch();
      } else {
        _snack(body['msg'] ?? 'Failed to save', AppColors.error);
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), AppColors.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Bank Details'),
        content: const Text('Are you sure you want to remove this bank account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = context.read<AuthProvider>().token ?? '';
    try {
      await http.delete(
        Uri.parse(ApiConstants.bankDetailById(id)),
        headers: {'Authorization': 'Bearer $token'},
      );
      _fetch();
    } catch (e) {
      if (mounted) _snack(e.toString(), AppColors.error);
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
        title: const Text('Bank Details'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _fetch, child: const Text('Retry')),
                  ],
                ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    // ── Approved lock banner ──────────────────────────────────
                    if (_approved)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, color: Color(0xFF16A34A), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bank Details Approved & Locked',
                                      style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 13, color: Color(0xFF16A34A))),
                                  SizedBox(height: 2),
                                  Text('Your payout details are verified. Contact support to make changes.',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Existing entries ──────────────────────────────────────
                    if (_bankDetails.isNotEmpty) ...[
                      const Text('Saved Accounts',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      ..._bankDetails.map((b) => _BankCard(
                            detail: b,
                            approved: _approved,
                            onDelete: () => _delete(b['_id'].toString()),
                          )),
                      const SizedBox(height: 24),
                    ],

                    // ── Add form (only if not approved) ───────────────────────
                    if (!_approved) ...[
                      const Text('Add Bank Account',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Once admin approves your bank details, they cannot be changed.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _field(_bankName, 'Bank Name', Icons.account_balance_outlined, required: true),
                            _field(_holderName, 'Account Holder Name', Icons.person_outline, required: true),
                            _field(_accountNumber, 'Account Number', Icons.pin_outlined,
                                keyboard: TextInputType.number, required: true),
                            _field(_ifsc, 'IFSC Code', Icons.tag_rounded, required: true),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: _accountType,
                              decoration: InputDecoration(
                                labelText: 'Account Type',
                                prefixIcon: const Icon(Icons.savings_outlined,
                                    size: 20, color: AppColors.textHint),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                              items: ['Savings', 'Current']
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (v) => setState(() => _accountType = v ?? 'Savings'),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _add,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _saving
                                    ? const CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2)
                                    : const Text('Save Bank Details',
                                        style: TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
        ),
      );
}

class _BankCard extends StatelessWidget {
  final Map<String, dynamic> detail;
  final bool approved;
  final VoidCallback onDelete;
  const _BankCard({required this.detail, required this.approved, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _row('Bank', detail['bankName']?.toString() ?? ''),
          _row('Account Holder', detail['holderName']?.toString() ?? ''),
          _row('Account Number', detail['accountNumber']?.toString() ?? ''),
          _row('IFSC Code', detail['ifscCode']?.toString() ?? ''),
          _row('Account Type', detail['accountType']?.toString() ?? ''),
          if (!approved) ...[
            const Divider(height: 20),
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              label: const Text('Remove', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ],
    ),
  );
}
