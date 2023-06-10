import 'package:flutter/material.dart';

class Damper {
  String label;
  List<String> positions;
  int currentPosition;

  Damper(this.label, this.positions, this.currentPosition);

  @override
  String toString() {
    return "$label, ${positions[currentPosition]}";
  }
}

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List<Damper> dampers = [];

  void addNewRadioButtonGroup() {
    setState(() {
      dampers.add(Damper(
          "Damper ${dampers.length + 1}", ["0", "25", "50", "75", "100"], 0));
    });
  }

  void deleteRadioButtonGroup(int index) {
    setState(() {
      print(dampers[index]);
      dampers.removeAt(index);
    });
  }

  void updatedSelected(int index, int? value) {
    setState(() {
      dampers[index].currentPosition = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Duct Damper Controller Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Air Duct Damper Controller Demo"),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Colors.white,
              ),
              onPressed: () {
                // do something
              },
            )
          ],
        ),
        body: ListView.builder(
          itemCount: dampers.length,
          itemBuilder: (context, index) {
            print("$index, ${dampers[index]}");
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: UniqueKey(),
                            initialValue: dampers[index].label,
                            decoration: InputDecoration(
                              labelText: 'Zone Name',
                            ),
                            onChanged: (value) => dampers[index].label = value,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => showDialog(
                              context: context,
                              builder: (BuildContext context) => Dialog(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                                'Are you sure you want to remove ${dampers[index].label}?'),
                                            const SizedBox(height: 15),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    deleteRadioButtonGroup(
                                                        index);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: dampers[index].positions.map((option) {
                        int optionIndex =
                            dampers[index].positions.indexOf(option);
                        return Column(
                          children: [
                            Radio(
                              value: optionIndex,
                              groupValue: dampers[index].currentPosition,
                              onChanged: (int? value) =>
                                  updatedSelected(index, value),
                            ),
                            Text(option),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: addNewRadioButtonGroup,
          tooltip: 'Add new group',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

void main() {
  runApp(App());
}
