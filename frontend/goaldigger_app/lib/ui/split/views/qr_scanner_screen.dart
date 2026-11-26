import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';

/// Full-screen camera scanner. Pops with the first 6-character invitation
/// code it recognises, or `null` when cancelled.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  static final RegExp _codePattern = RegExp(r'[A-Z0-9]{6}');

  /// Extracts an invitation code from raw scanned text.
  static String? extractCode(String raw) {
    return _codePattern.firstMatch(raw.toUpperCase())?.group(0);
  }

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) {
      return;
    }
    final raw = capture.barcodes.first.rawValue;
    final code = raw == null ? null : QrScannerScreen.extractCode(raw);
    if (code != null) {
      _handled = true;
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描 QR Code'),
        backgroundColor: AppColors.pinkPrimary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => const _CameraError(),
          ),
          const Positioned.fill(child: _ScanOverlay()),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.pinkPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '取消',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            '相機無法啟動',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '請手動輸入邀請碼',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  static const _frameSize = 200.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: SizedBox(
          width: _frameSize,
          height: _frameSize,
          child: Stack(
            children: [
              Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
              Positioned(
                top: 0,
                right: 0,
                child: _Corner(top: true, left: false),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: _Corner(top: false, left: true),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _Corner(top: false, left: false),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 32, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      '將 QR Code 對準框內',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.pinkPrimary, width: 4);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
      ),
    );
  }
}
