import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
//import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
//import 'package:intl/intl.dart';
//import 'dart:ffi';

void main() async {
  //WidgetsFlutterBinding.ensureInitialized();
  //await AndroidAlarmManager.initialize();
  runApp(AttendanceTrackerApp());
}


class AttendanceTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Tracker',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green[700],
        //colorScheme: ColorScheme.light().copyWith(primary: Colors.black),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green
      ),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: AttendanceTrackerScreen(),
    );
  }
}

class AttendanceTrackerScreen extends StatefulWidget {
  @override
  _AttendanceTrackerScreenState createState() => _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  List<Course> courses = [];
  late SharedPreferences _prefs;
  List<List<String>> weeklyTimetables = List.generate(5, (_) => List.filled(7, ''));
  List<List<String>> selectedTimetable = List.generate(5, (_) => List.filled(7, ''));
  late Timer _attendanceTimer;
  ScrollController _scrollController = ScrollController();
  bool _isButtonVisible = true;
  
  @override
  void initState() {
    super.initState();
    _loadSelectedTimetable();
    _loadCourses();

    // Add a listener to the ScrollController
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        // User is scrolling up, show the button
        setState(() {
          _isButtonVisible = true;
        });
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        // User is scrolling down, hide the button
        setState(() {
          _isButtonVisible = false;
        });
      }
    });
  }

  //void _updateAttendanceInBackground() {
    //print('Background task: Updating attendance...');
    //_updateAttendance();
  //}
  @override
  void dispose(){
    _attendanceTimer.cancel();
    super.dispose();
  }
  
  // ignore: unused_element
  void _updateAttendance() {
  //print('Updating attendance...'); // Debugging line
  DateTime now = DateTime.now();
  int dayIndex = now.weekday - 1;
  //print('Day Index: $dayIndex'); // Debugging line

  if (dayIndex >= 0 && dayIndex < 5) {
    List<String> courseNames = selectedTimetable[dayIndex];
    //print('Course Names: $courseNames'); // Debugging line

    for (String courseName in courseNames) {
      if (courseName.isNotEmpty) {
        int courseIndex = courses.indexWhere((course) => course.name == courseName);
        if (courseIndex != -1) {
          //print('Updating attendance for course: $courseName'); // Debugging line
          setState(() {
            courses[courseIndex].attendedHours += 1;
            courses[courseIndex].conductedHours +=1;
            courses[courseIndex].attendance = (courses[courseIndex].attendedHours / courses[courseIndex].conductedHours) * 100;
            _saveCourses();
            });
          }
        }
      }
    }
  }


  void _setTimetable() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetTimetableScreen(weeklyTimetables, courses, selectedTimetable)), // Pass courses list here
    );

    // Handle the result returned from the SetTimetableScreen
    if (result != null && result is List<List<String>>) {
      setState(() {
        weeklyTimetables = result;
      });
    }
  }

  void _showTimetable() async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SetTimetableScreen(weeklyTimetables, courses, selectedTimetable)),
  );
}


  Future<void> _loadSelectedTimetable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load the flat list from SharedPreferences
    List<String> flatList = prefs.getStringList('selectedTimetable') ?? [];
    
    // Convert the flat list back to a nested list
    List<List<String>> loadedTimetable = List.generate(5, (dayIndex) => flatList.sublist(dayIndex * 7, (dayIndex + 1) * 7));

    setState(() {
      selectedTimetable = loadedTimetable;
    });
  }
  
  void _bunkCourse(int index) {
    setState(() {
      if (courses[index].attendedHours > 0) {
        courses[index].attendedHours -= 1;
        courses[index].attendance = (courses[index].attendedHours / courses[index].conductedHours) * 100;
        _saveCourses();
      }
    });
  }

  Future<void> _loadCourses() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String>? courseList = _prefs.getStringList('courses');
    if (courseList != null) {
      setState(() {
        courses = courseList.map((json) => Course.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveCourses() async {
    final List<String> courseList = courses.map((course) => course.toJson()).toList();
    await _prefs.setStringList('courses', courseList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Tracker',
          style: TextStyle(
            fontFamily: "SanFrancisco",
            fontWeight: FontWeight.bold,
          ),
        ),
        //elevation: 4,
        shadowColor: Theme.of(context).shadowColor,
        actions: [
          /*IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _addCourse();
            },
          ),*/
        ],
        centerTitle: true,
      ),
      drawer: _buildDrawer(), // Add this line to include the drawer
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return _buildCourseItem(index);
            },
          ),
        ],
      ),
      floatingActionButton: _isButtonVisible
    ? FloatingActionButton(
        onPressed: () {
          _addCourse(); // Call your _addCourse method when the button is pressed
        },
        child: Icon(Icons.add),
      )
    : null,
    );
  }

Widget _buildDrawer() {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 115,
          decoration: BoxDecoration(
            //color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(90, 65, 0, 0),
            child: Text(
              'Options',
              style: TextStyle(
                //color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: "SanFrancisco",
              ),
            ),
          ),
        ),
        ListTile(
          title: Text('Add Course'),
          onTap: () {
            Navigator.pop(context);
            _addCourse();
          },
        ),
        ListTile(
          title: Text('Set Timetable'), // Add the "Set Timetable" option
          onTap: () {
            Navigator.pop(context); // Close the drawer
            _setTimetable(); // Call the _setTimetable method
          },
        ),
        // Add more ListTiles for additional menu items
        ListTile(
          title: Text('Show Timetable'), // Add the "Show Timetable" option
          onTap: () {
            Navigator.pop(context); // Close the drawer
            _showTimetable(); // Call the _showTimetable method
          },
        ),
        ListTile(
          title: Text('Item 3'),
          onTap: () {
            // Handle the item 3 action
          },
        ),
        // ... Add more ListTiles as needed ...
      ],
    ),
  );
}

  Widget _buildCourseItem(int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        //side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  courses[index].name,
                  style: TextStyle(
                    fontFamily: "SanFrancisco",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                    //color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editCourse(index);
                  },
                ),
              ],
            ),
            SizedBox(height: 0),
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: courses[index].attendance / 100,
                  strokeWidth: 4,
                ),
                Positioned(
                  top: 11.5, // Adjust the top position
                  child: Text(
                    '${courses[index].attendance.toInt()}%',
                    style: TextStyle(
                      fontFamily: "SanFrancisco",
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Hours Attended: ${courses[index].attendedHours.toInt()}',
              style: TextStyle(
                fontFamily: "SanFrancisco",
                fontSize: 14,
              ),
            ),
            Text(
              'Hours Conducted: ${courses[index].conductedHours.toInt()}',
              style: TextStyle(
                fontFamily: "SanFrancisco",
                fontSize: 14,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _increaseBoth(index);
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    _bunkCourse(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.red,
                    
                  ),
                  child: Text(
                    'Bunked',
                    style: TextStyle(
                      fontFamily: "SanFrancisco",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteCourse(index);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addCourse() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCourseScreen()),
    );

    if (result != null && result is Course) {
      setState(() {
        courses.add(result);
        _saveCourses();
      });
    }
  }

  void _editCourse(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditCourseScreen(course: courses[index])),
    );

    if (result != null && result is Course) {
      setState(() {
        courses[index] = result;
        _saveCourses();
      });
    }
  }

  void _increaseBoth(int index) {
    setState(() {
      courses[index].conductedHours += 1;
      courses[index].attendedHours += 1;
      courses[index].attendance = (courses[index].attendedHours / courses[index].conductedHours) * 100;
      _saveCourses();
    });
  }

  void _deleteCourse(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Course'),
          content: Text('Are you sure you want to delete this course?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  courses.removeAt(index);
                  _saveCourses();
                  Navigator.pop(context);
                });
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }
}

class SetTimetableScreen extends StatefulWidget {
  final List<List<String>> weeklyTimetables;
  final List<Course> courses;
  final List<List<String>> selectedTimetable;

  SetTimetableScreen(this.weeklyTimetables, this.courses, this.selectedTimetable);

  @override
  _SetTimetableScreenState createState() => _SetTimetableScreenState();
}





class _SetTimetableScreenState extends State<SetTimetableScreen> {
  List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Timetable'),
        //elevation: 4,
      ),
      body: ListView.builder(
        itemCount: dayNames.length,
        itemBuilder: (context, dayIndex) {
          String dayName = dayNames[dayIndex];
          return ListTile(
            title: Text(dayName),
            subtitle: Column(
              children: [
                for (int slotIndex = 0; slotIndex < 7; slotIndex++)
                  DropdownButton<Course>(
                    value: widget.selectedTimetable[dayIndex][slotIndex] == '' ? null : widget.courses.firstWhere((course) => course.name == widget.selectedTimetable[dayIndex][slotIndex], orElse: () => widget.courses[0]),
                    onChanged: (newValue) {
                      setState(() {
                        widget.selectedTimetable[dayIndex][slotIndex] = newValue?.name ?? '';
                        _saveSelectedTimetable();
                      });
                    },
                    items: [
                      DropdownMenuItem<Course>(
                        value: null,
                        child: Text('Select Course'),
                      ),
                      ...widget.courses.map((course) {
                        return DropdownMenuItem<Course>(
                          value: course,
                          child: Text(course.name),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, widget.selectedTimetable);
        },
        child: Icon(Icons.check),
      ),
    );
  }
  Future<void> _saveSelectedTimetable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert the nested list to a flat list of strings
    List<String> flatList = widget.selectedTimetable.expand((row) => row).toList();

    // Save the flat list to SharedPreferences
    prefs.setStringList('selectedTimetable', flatList);
  }
}





class AddCourseScreen extends StatefulWidget {
  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController conductedHoursController = TextEditingController();
  TextEditingController attendedHoursController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Course Name',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: conductedHoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hours Conducted',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: attendedHoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hours Attended',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _addCourse();
              },
              child: Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }

  void _addCourse() {
    String name = nameController.text;
    double conductedHours = double.tryParse(conductedHoursController.text) ?? 0;
    double attendedHours = double.tryParse(attendedHoursController.text) ?? 0;

    if (name.isNotEmpty && conductedHours > 0 && attendedHours >= 0 && attendedHours <= conductedHours) {
      double attendance = (attendedHours / conductedHours) * 100;
      Course course = Course(name, attendance, conductedHours, attendedHours);
      Navigator.pop(context, course);
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill in valid values.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

class EditCourseScreen extends StatefulWidget {
  final Course course;

  EditCourseScreen({required this.course});

  @override
  _EditCourseScreenState createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController conductedHoursController = TextEditingController();
  TextEditingController attendedHoursController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    nameController.text = widget.course.name;
    conductedHoursController.text = widget.course.conductedHours.toStringAsFixed(1);
    attendedHoursController.text = widget.course.attendedHours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Course Name',
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Text('Conducted Hours:'),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      widget.course.conductedHours -= 1;
                      conductedHoursController.text = widget.course.conductedHours.toStringAsFixed(1);
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      widget.course.conductedHours += 1;
                      conductedHoursController.text = widget.course.conductedHours.toStringAsFixed(1);
                    });
                  },
                ),
              ],
            ),
            TextField(
              controller: conductedHoursController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  widget.course.conductedHours = double.tryParse(value) ?? 0;
                });
              },
              decoration: InputDecoration(
                labelText: 'Hours Conducted',
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Text('Attended Hours:'),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      widget.course.attendedHours -= 1;
                      attendedHoursController.text = widget.course.attendedHours.toStringAsFixed(1);
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      widget.course.attendedHours += 1;
                      attendedHoursController.text = widget.course.attendedHours.toStringAsFixed(1);
                    });
                  },
                ),
              ],
            ),
            TextField(
              controller: attendedHoursController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  widget.course.attendedHours = double.tryParse(value) ?? 0;
                });
              },
              decoration: InputDecoration(
                labelText: 'Hours Attended',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _editCourse();
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _editCourse() {
    String name = nameController.text;
    double conductedHours = double.tryParse(conductedHoursController.text) ?? 0;
    double attendedHours = double.tryParse(attendedHoursController.text) ?? 0;

    if (name.isNotEmpty && conductedHours > 0 && attendedHours >= 0 && attendedHours <= conductedHours) {
      double attendance = (attendedHours / conductedHours) * 100;
      Course editedCourse = Course(name, attendance, conductedHours, attendedHours);
      Navigator.pop(context, editedCourse);
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill in valid values.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

class Course {
  final String name;
  double attendance;
  double conductedHours;
  double attendedHours;

  Course(this.name, this.attendance, this.conductedHours, this.attendedHours);

  factory Course.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json);
    return Course(
      data['name'] as String,
      data['attendance'] as double,
      data['conductedHours'] as double,
      data['attendedHours'] as double,
    );
  }

  String toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'attendance': attendance,
      'conductedHours': conductedHours,
      'attendedHours': attendedHours,
    };
    return jsonEncode(data);
  }
}
