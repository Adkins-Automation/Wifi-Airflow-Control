import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanPage extends StatefulWidget {
  @override
  QRScanPageState createState() => QRScanPageState();
}

class QRScanPageState extends State<QRScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  StreamSubscription<Barcode>? subscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    subscription = controller.scannedDataStream.listen((scanData) {
      subscription?.cancel();
      Navigator.pop(context, scanData.code);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    controller?.dispose();
    super.dispose();
  }
}
