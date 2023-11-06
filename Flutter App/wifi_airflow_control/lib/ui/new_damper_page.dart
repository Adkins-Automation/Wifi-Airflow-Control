import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:wifi_airflow_control/ui/qr_scan_page.dart';

class NewDamperPage extends StatefulWidget {
  @override
  NewDamperPageState createState() => NewDamperPageState();
}

class NewDamperPageState extends State<NewDamperPage> {
  final damperIdController = TextEditingController();
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  bool enableConnect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: damperIdController,
              onChanged: (value) {
                setState(() {
                  enableConnect =
                      value.isNotEmpty && ssidController.text.isNotEmpty;
                });
              },
              decoration: InputDecoration(hintText: "Damper ID"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: ssidController,
              onChanged: (value) {
                setState(() {
                  enableConnect =
                      value.isNotEmpty && damperIdController.text.isNotEmpty;
                });
              },
              decoration: InputDecoration(hintText: "SSID"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(hintText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 10),
            ElevatedButton(
                child: Text('SCAN QR CODE'),
                onPressed: () async {
                  final scannedResult = await Navigator.push<String?>(
                    context,
                    MaterialPageRoute(builder: (context) => QRScanPage()),
                  );

                  if (scannedResult != null) {
                    setState(() {
                      damperIdController.text = scannedResult;
                    });
                  }
                }),
            // TODO: add qr scanner for wifi creds
            ElevatedButton(
              onPressed: (enableConnect)
                  ? () {
                      FlutterBlue.instance.isOn.then((isOn) {
                        if (isOn) {
                          Navigator.pop(context, {
                            'damperId': damperIdController.text,
                            'ssid': ssidController.text,
                            'password': passwordController.text,
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Please enable Bluetooth on your phone')),
                          );
                        }
                      });
                    }
                  : null,
              child: Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
