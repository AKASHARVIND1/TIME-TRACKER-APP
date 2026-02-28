import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(TimeTrackerApp());
}

class TimeTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TimeTrack Pro',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomeScreen(),
    );
  }
}

class TimeEntry {
  final String id;
  final String project;
  final String task;
  final String hours;
  final String notes;
  final String date;

  TimeEntry({
    required this.id,
    required this.project,
    required this.task,
    required this.hours,
    required this.notes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "project": project,
      "task": task,
      "hours": hours,
      "notes": notes,
      "date": date,
    };
  }

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map["id"],
      project: map["project"],
      task: map["task"],
      hours: map["hours"],
      notes: map["notes"],
      date: map["date"],
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> projects = [];
  List<String> tasks = [];
  List<TimeEntry> entries = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= SAVE DATA =================

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList("projects", projects);
    await prefs.setStringList("tasks", tasks);

    List<String> entryList =
        entries.map((e) => jsonEncode(e.toMap())).toList();

    await prefs.setStringList("entries", entryList);
  }

  // ================= LOAD DATA =================

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      projects = prefs.getStringList("projects") ?? [];
      tasks = prefs.getStringList("tasks") ?? [];

      List<String> entryList =
          prefs.getStringList("entries") ?? [];

      entries = entryList
          .map((e) => TimeEntry.fromMap(jsonDecode(e)))
          .toList();
    });
  }

  // ================= ENTRY FUNCTIONS =================

  void addEntry(TimeEntry entry) {
    setState(() {
      entries.add(entry);
    });
    saveData();
  }

  void deleteEntry(int index) {
    setState(() {
      entries.removeAt(index);
    });
    saveData();
  }

  // ================= GROUPING FUNCTION =================

  List<Widget> groupEntries() {
    Map<String, List<TimeEntry>> grouped = {};

    for (var entry in entries) {
      grouped.putIfAbsent(entry.project, () => []);
      grouped[entry.project]!.add(entry);
    }

    List<Widget> widgets = [];

    grouped.forEach((project, projectEntries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            project,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ),
      );

      for (var entry in projectEntries) {
        int index = entries.indexOf(entry);

        widgets.add(
          Dismissible(
            key: Key(entry.id),
            background: Container(color: Colors.red),
            onDismissed: (_) => deleteEntry(index),
            child: ListTile(
              title: Text(entry.task),
              subtitle: Text(
                  "${entry.hours} hrs | ${entry.notes}\n${entry.date}"),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  // ================= NAVIGATION =================

  void openAddEntryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(
          projects: projects,
          tasks: tasks,
          onAdd: addEntry,
        ),
      ),
    );
  }

  void openProjects() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectScreen(
          projects: projects,
          onUpdate: () {
            setState(() {});
            saveData();
          },
        ),
      ),
    );
  }

  void openTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskScreen(
          tasks: tasks,
          onUpdate: () {
            setState(() {});
            saveData();
          },
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration:
                  BoxDecoration(color: Colors.indigo),
              child: Text("Menu",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22)),
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text("Projects"),
              onTap: openProjects,
            ),
            ListTile(
              leading: Icon(Icons.task),
              title: Text("Tasks"),
              onTap: openTasks,
            ),
          ],
        ),
      ),
      appBar: AppBar(title: Text("TimeTrack Pro")),
      body: entries.isEmpty
          ? Center(
              child: Text(
                "No Time Entries Yet!",
                style: TextStyle(fontSize: 20),
              ),
            )
          : ListView(
              children: groupEntries(),
            ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: openAddEntryScreen,
        child: Icon(Icons.add),
      ),
    );
  }
}

// ================= ADD ENTRY SCREEN =================

class AddEntryScreen extends StatefulWidget {
  final List<String> projects;
  final List<String> tasks;
  final Function(TimeEntry) onAdd;

  AddEntryScreen({
    required this.projects,
    required this.tasks,
    required this.onAdd,
  });

  @override
  _AddEntryScreenState createState() =>
      _AddEntryScreenState();
}

class _AddEntryScreenState
    extends State<AddEntryScreen> {
  String? selectedProject;
  String? selectedTask;

  final hoursController = TextEditingController();
  final notesController = TextEditingController();
  final dateController = TextEditingController();

  void submitEntry() {
    if (selectedProject != null &&
        selectedTask != null &&
        hoursController.text.isNotEmpty &&
        dateController.text.isNotEmpty) {
      widget.onAdd(
        TimeEntry(
          id: DateTime.now()
              .millisecondsSinceEpoch
              .toString(),
          project: selectedProject!,
          task: selectedTask!,
          hours: hoursController.text,
          notes: notesController.text,
          date: dateController.text,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("Add Time Entry")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  labelText: "Select Project"),
              value: selectedProject,
              items: widget.projects
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() =>
                      selectedProject = value),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  labelText: "Select Task"),
              value: selectedTask,
              items: widget.tasks
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() =>
                      selectedTask = value),
            ),
            SizedBox(height: 10),
            TextField(
              controller: hoursController,
              decoration: InputDecoration(
                  labelText: "Total Hours"),
              keyboardType:
                  TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                  labelText: "Notes"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: dateController,
              decoration:
                  InputDecoration(labelText: "Date"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitEntry,
              child: Text("Add TimeEntry"),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PROJECT SCREEN =================

class ProjectScreen extends StatefulWidget {
  final List<String> projects;
  final VoidCallback onUpdate;

  ProjectScreen(
      {required this.projects,
      required this.onUpdate});

  @override
  _ProjectScreenState createState() =>
      _ProjectScreenState();
}

class _ProjectScreenState
    extends State<ProjectScreen> {
  void addProject() {
    TextEditingController controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Project"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              labelText: "Project Name"),
        ),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.projects
                      .add(controller.text);
                });
                widget.onUpdate();
              }
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Projects")),
      body: widget.projects.isEmpty
          ? Center(
              child: Text(
                  "No Projects Added Yet"))
          : ListView.builder(
              itemCount: widget.projects.length,
              itemBuilder: (_, i) =>
                  ListTile(
                      title:
                          Text(widget.projects[i])),
            ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: addProject,
        child: Icon(Icons.add),
      ),
    );
  }
}

// ================= TASK SCREEN =================

class TaskScreen extends StatefulWidget {
  final List<String> tasks;
  final VoidCallback onUpdate;

  TaskScreen(
      {required this.tasks,
      required this.onUpdate});

  @override
  _TaskScreenState createState() =>
      _TaskScreenState();
}

class _TaskScreenState
    extends State<TaskScreen> {
  void addTask() {
    TextEditingController controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Task"),
        content: TextField(
          controller: controller,
          decoration:
              InputDecoration(labelText: "Task Name"),
        ),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.tasks
                      .add(controller.text);
                });
                widget.onUpdate();
              }
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasks")),
      body: widget.tasks.isEmpty
          ? Center(
              child: Text("No Tasks Added Yet"))
          : ListView.builder(
              itemCount: widget.tasks.length,
              itemBuilder: (_, i) =>
                  ListTile(
                      title:
                          Text(widget.tasks[i])),
            ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: addTask,
        child: Icon(Icons.add),
      ),
    );
  }
}