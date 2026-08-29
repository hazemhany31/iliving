import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config/app_secrets.dart';
import '../models/gate_pass.dart';
import '../repositories/firestore/firestore_gate_repository.dart';
import '../services/gate_service.dart';

class GatePassVerifierScreen extends StatefulWidget {
  const GatePassVerifierScreen({super.key});

  @override
  State<GatePassVerifierScreen> createState() => _GatePassVerifierScreenState();
}

class _GatePassVerifierScreenState extends State<GatePassVerifierScreen> {
  final TextEditingController _payloadController = TextEditingController();
  final GateService _gateService =
      GateService(gateRepository: FirestoreGateRepository());
  bool _isVerifying = false;
  GatePassVerificationResult? _result;

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  Future<void> _verifyPayload() async {
    final raw = _payloadController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _result = GatePassVerificationResult.invalid(
            'INVALID', 'Paste the signed gate-pass QR payload to verify it.');
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _result = null;
    });

    final result = await _gateService.verifyAndLoadGatePass(
      payload: raw,
      secretKey: AppSecrets.instance.gateSigningKey,
      gateRepository: FirestoreGateRepository(),
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _result?.isValid ?? false;
    final statusColor = isValid ? Colors.green : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Pass Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Security scan result',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste or scan the encoded payload from the gate pass. The app verifies the signature, checks expiry, and confirms usage limits before granting access.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _payloadController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'QR payload / pass code',
                  hintText: 'ILIVING-GATE-PASS:...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isVerifying ? null : _verifyPayload,
                      icon: const Icon(Icons.verified_rounded),
                      label:
                          Text(_isVerifying ? 'Verifying...' : 'Verify Pass'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final text = await Clipboard.getData('text/plain');
                      if (text?.text != null) {
                        _payloadController.text = text!.text!;
                      }
                    },
                    icon: const Icon(Icons.content_paste_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withAlpha(160)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isValid
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _result!.statusLabel,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _result!.message,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_result!.pass != null) ...[
                        const SizedBox(height: 12),
                        Text('Compound: ${_result!.pass!.compoundId}'),
                        Text('Unit: ${_result!.pass!.unitId}'),
                        Text('Host: ${_result!.pass!.hostUserId}'),
                        Text('Visitor: ${_result!.pass!.visitorName}'),
                        Text('Type: ${_result!.pass!.passType.name}'),
                        Text(
                            'Valid until: ${_result!.pass!.validUntil.toLocal().toString()}'),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
