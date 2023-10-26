import 'package:flutter/material.dart';
import 'package:wifi_airflow_control/ui/qr_scan_page.dart';

class NewDamperPage extends StatefulWidget {
  @override
  NewDamperPageState createState() => NewDamperPageState();
}

class NewDamperPageState extends State<NewDamperPage> {
  String? damperId;
  String? ssid;
  String password = ''; // optional

  final damperIdController = TextEditingController();
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    damperId = "08b61f82f372";
    ssid = "Zenfone 9_3070";
    password = "mme9h4xpeq9mtdw";
    // ssid = "Adkins";
    // password = "chuck1229";

    damperIdController.text = damperId ?? '';
    ssidController.text = ssid ?? '';
    passwordController.text = password;

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
                damperId = value;
              },
              decoration: InputDecoration(hintText: "Damper ID"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: ssidController,
              onChanged: (value) {
                ssid = value;
              },
              decoration: InputDecoration(hintText: "SSID"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              onChanged: (value) {
                password = value;
              },
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
                      damperId = scannedResult;
                      damperIdController.text = scannedResult;
                    });
                  }
                }),
            ElevatedButton(
              onPressed: (damperId != null &&
                      damperId!.isNotEmpty &&
                      ssid != null &&
                      ssid!.isNotEmpty)
                  ? () {
                      Navigator.pop(context, {
                        'damperId': damperId,
                        'ssid': ssid,
                        'password': password,
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
