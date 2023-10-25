import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:i_flow/dto/damper.dart';
import 'package:i_flow/ui/widgets/damper_slider.dart';
import 'package:i_flow/util/constants.dart';

class SchedulePage extends StatefulWidget {
  final Damper damper;

  SchedulePage(this.damper);

  @override
  SchedulePageState createState() => SchedulePageState();
}

class SchedulePageState extends State<SchedulePage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.refFromURL(firebaseUrl);
  int selectedDayOfWeek = 0;

  void _updateDamperSchedule(Damper damper) {
    final scheduleData =
        damper.schedule?.map((key, value) => MapEntry("d$key", value));

    // Point to the specific damper's schedule in the database
    _db
        .child(_auth.currentUser!.uid)
        .child(damper.id)
        .child('schedule')
        .set(scheduleData)
        .then((_) {
      print("Damper schedule updated successfully in Realtime Database");
    }).catchError((error) {
      print("Error updating damper schedule in Realtime Database: $error");
      print(scheduleData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedDayOfWeek = index;
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor:
                        selectedDayOfWeek == index ? Colors.blue : Colors.grey,
                    child: Text(
                      ["M", "T", "W", "T", "F", "S", "S"][index],
                      style: TextStyle(
                        color: selectedDayOfWeek == index
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount:
                  widget.damper.schedule?[selectedDayOfWeek]?.keys.length ?? 0,
              itemBuilder: (context, index) {
                var sortedTimes =
                    widget.damper.schedule?[selectedDayOfWeek]?.keys.toList();
                sortedTimes?.sort();
                var time = sortedTimes?[index];
                var position =
                    widget.damper.schedule?[selectedDayOfWeek]?[time];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Center(
                              child: Text(
                                  "${(time! ~/ 100).toString().padLeft(2, '0')}:${(time % 100).toString().padLeft(2, '0')}"),
                            )),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(() {
                                widget.damper.schedule?[selectedDayOfWeek]
                                    ?.remove(time);
                                _updateDamperSchedule(widget.damper);
                              }),
                            ),
                          ],
                        ),
                        DamperSlider(
                          initialValue: position!,
                          onEnd: (value) {
                            setState(() {
                              widget.damper.schedule?[selectedDayOfWeek]
                                  ?[time] = value.toInt();
                              _updateDamperSchedule(widget.damper);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var now = DateTime.now();
          var time = TimeOfDay(hour: now.hour, minute: now.minute);
          showTimePicker(
            context: context,
            initialTime: time,
          ).then((value) {
            if (value != null) {
              var time = value.hour * 100 + value.minute;
              widget.damper.schedule ??= {};
              widget.damper.schedule?[selectedDayOfWeek] ??= {};
              setState(() {
                widget.damper.schedule?[selectedDayOfWeek]?[time] = 0;
                _updateDamperSchedule(widget.damper);
              });
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
