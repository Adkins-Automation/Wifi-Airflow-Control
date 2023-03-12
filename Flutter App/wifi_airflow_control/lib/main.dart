import 'package:flutter/material.dart';

class RadioButtonGroup {
  String label;
  List<String> options;
  int selectedOptionIndex;

  RadioButtonGroup(this.label, this.options, this.selectedOptionIndex);

  @override
  String toString() {
    return "$label, ${options[selectedOptionIndex]}";
  }
}

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List<RadioButtonGroup> radioButtonGroups = [];

  void addNewRadioButtonGroup() {
    setState(() {
      radioButtonGroups.add(RadioButtonGroup(
          "Group ${radioButtonGroups.length + 1}",
          ["0", "25", "50", "75", "100"],
          0));
    });
  }

  void deleteRadioButtonGroup(int index) {
    setState(() {
      print(radioButtonGroups[index]);
      radioButtonGroups.removeAt(index);
    });
  }

  void updatedSelected(int index, int? value) {
    setState(() {
      radioButtonGroups[index].selectedOptionIndex = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Duct Damper Controller Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Air Duct Damper Controller Demo"),
        ),
        body: ListView.builder(
          itemCount: radioButtonGroups.length,
          itemBuilder: (context, index) {
            print("$index, ${radioButtonGroups[index]}");
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
                            initialValue: radioButtonGroups[index].label,
                            decoration: InputDecoration(
                              labelText: 'Zone Name',
                            ),
                            onChanged: (value) =>
                                radioButtonGroups[index].label = value,
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
                                                'Are you sure you want to remove ${radioButtonGroups[index].label}?'),
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
                      children: radioButtonGroups[index].options.map((option) {
                        int optionIndex =
                            radioButtonGroups[index].options.indexOf(option);
                        return Column(
                          children: [
                            Radio(
                              value: optionIndex,
                              groupValue:
                                  radioButtonGroups[index].selectedOptionIndex,
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
