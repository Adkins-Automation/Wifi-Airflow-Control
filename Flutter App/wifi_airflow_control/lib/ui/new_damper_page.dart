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
        child: SingleChildScrollView(
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
                        var damperId = parseDamperId(scannedResult);
                        if (damperId != null) {
                          damperIdController.text = damperId;
                        } else {
                          var wifiInfo = parseWifiQR(scannedResult);
                          if (wifiInfo.containsKey('S')) {
                            ssidController.text = wifiInfo['S']!;
                            if (wifiInfo.containsKey('P')) {
                              passwordController.text = wifiInfo['P']!;
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invalid QR Code')),
                            );
                          }
                        }
                        enableConnect = damperIdController.text.isNotEmpty &&
                            ssidController.text.isNotEmpty;
                      });
                    }
                  }),
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
      ),
    );
  }

  Map<String, String> parseWifiQR(String qrResult) {
    Map<String, String> wifiInfo = {};

    if (qrResult.startsWith('WIFI:')) {
      qrResult = qrResult.substring(5); // Remove 'WIFI:' prefix
      List<String> parts = qrResult.split(';');
      for (String part in parts) {
        List<String> keyValue = part.split(':');
        if (keyValue.length == 2) {
          wifiInfo[keyValue[0]] = keyValue[1];
        }
      }
    }
    return wifiInfo;
  }

  String? parseDamperId(String qrResult) {
    if (qrResult.startsWith('DAMPER:')) {
      return qrResult.substring(7);
    }
    return null;
  }
}
