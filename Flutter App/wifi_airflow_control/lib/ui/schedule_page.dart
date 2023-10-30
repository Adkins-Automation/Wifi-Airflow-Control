import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:wifi_airflow_control/dto/damper.dart';
import 'package:wifi_airflow_control/dto/schedule.dart';
import 'package:wifi_airflow_control/ui/widgets/damper_slider.dart';
import 'package:wifi_airflow_control/util/constants.dart';

class SchedulePage extends StatefulWidget {
  final Damper damper;

  SchedulePage(this.damper);

  @override
  SchedulePageState createState() => SchedulePageState();
}

class SchedulePageState extends State<SchedulePage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.refFromURL(firebaseUrl);
  Damper? damper;

  void _updateDamperSchedule() {
    Map<String, Map<String, int>> scheduleForFirebase =
        damper!.scheduleForFirebase();

    _db
        .child(_auth.currentUser!.uid)
        .child(widget.damper.id)
        .update({'schedule': scheduleForFirebase}).then((_) {
      print("Damper schedule updated successfully in Realtime Database");
    }).catchError((error) {
      print("Error updating damper schedule in Realtime Database: $error");
    });
  }

  void _updateSchedulePause() {
    _db
        .child(_auth.currentUser!.uid)
        .child(widget.damper.id)
        .update({'pauseSchedule': damper!.pauseSchedule}).then((_) {
      print("Damper schedule pause updated successfully in Realtime Database");
    }).catchError((error) {
      print(
          "Error updating damper schedule pause in Realtime Database: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    damper = damper ?? widget.damper;
    List<int> times = damper!.schedule.keys.toList();
    times.sort();
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Row(
              children: [
                Text("Pause Schedule"),
                Switch(
                  value: damper!.pauseSchedule,
                  onChanged: (value) {
                    setState(() {
                      damper!.pauseSchedule = value;
                      _updateSchedulePause();
                    });
                  },
                  activeColor: Colors.blue,
                )
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
            itemCount: damper!.schedule.length,
            itemBuilder: (context, index) {
              print("days: ${damper!.schedule[times[index]]!.days}");
              int hour = damper!.schedule[times[index]]!.time ~/ 100;
              int minute = damper!.schedule[times[index]]!.time % 100;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
                                style: TextStyle(fontSize: 42.0),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() {
                              damper!.schedule.remove(times[index]);
                              _updateDamperSchedule();
                            }),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(8, (dayIndex) {
                          print(
                              "isDaySet: $dayIndex, ${damper!.schedule[times[index]]!.isDaySet(Schedule.getDay(dayIndex))}");
                          if (dayIndex == 7) {
                            return Switch(
                              value: damper!.schedule[times[index]]!
                                  .isDaySet(Schedule.everyday),
                              onChanged: (active) {
                                setState(() {
                                  if (damper!.schedule[times[index]]!
                                      .isDaySet(Schedule.everyday)) {
                                    damper!.schedule[times[index]]!
                                        .unsetDay(Schedule.everyday);
                                  } else {
                                    damper!.schedule[times[index]]!
                                        .setDay(Schedule.everyday);
                                  }

                                  _updateDamperSchedule();
                                });
                              },
                            );
                          }
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (damper!.schedule[times[index]]!
                                    .isDaySet(Schedule.getDay(dayIndex))) {
                                  damper!.schedule[times[index]]!
                                      .unsetDay(Schedule.getDay(dayIndex));
                                } else {
                                  damper!.schedule[times[index]]!
                                      .setDay(Schedule.getDay(dayIndex));
                                }

                                _updateDamperSchedule();
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: damper!.schedule[times[index]]!
                                      .isDaySet(Schedule.getDay(dayIndex))
                                  ? Colors.blue
                                  : Colors.grey,
                              child: Text(
                                ["M", "T", "W", "T", "F", "S", "S"][dayIndex],
                                style: TextStyle(
                                  color: damper!.schedule[times[index]]!
                                          .isDaySet(Schedule.getDay(dayIndex))
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      DamperSlider(
                        initialValue: damper!.schedule[times[index]]!.position,
                        onEnd: (value) {
                          setState(() {
                            damper!.schedule[times[index]]!.position =
                                value.toInt();
                            _updateDamperSchedule();
                          });
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          )),
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
              var selectedTime = value.hour * 100 + value.minute;
              if (times.contains(selectedTime)) {
                return;
              }
              setState(() {
                //times.add(selectedTime);
                damper!.schedule[selectedTime] =
                    Schedule(selectedTime, 0, damper!.currentPosition);
                _updateDamperSchedule();
              });
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
