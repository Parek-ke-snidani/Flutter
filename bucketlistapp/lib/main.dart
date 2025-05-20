import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(prefs),
      child: TodoApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  List<Task> _tasks = [];
  List<Task> _completedTasks = [];
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'cs';

  AppState(this.prefs) {
    _loadTasks();
    _loadSettings();
  }

  List<Task> get tasks => _tasks;
  List<Task> get completedTasks => _completedTasks;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;

  void _loadTasks() {
    final tasksJson = prefs.getStringList('tasks') ?? [];
    final completedTasksJson = prefs.getStringList('completedTasks') ?? [];

    _tasks = tasksJson
        .map((taskJson) => Task.fromJson(json.decode(taskJson)))
        .toList();
    _completedTasks = completedTasksJson
        .map((taskJson) => Task.fromJson(json.decode(taskJson)))
        .toList();
  }

  void _saveTasks() {
    prefs.setStringList(
      'tasks',
      _tasks.map((task) => json.encode(task.toJson())).toList(),
    );
    prefs.setStringList(
      'completedTasks',
      _completedTasks.map((task) => json.encode(task.toJson())).toList(),
    );
  }

  void _loadSettings() {
    _themeMode =
        ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.light.index];
    _language = prefs.getString('language') ?? 'cs';
  }

  void addTask(String title) {
    final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(), title: title);
    _tasks.add(task);
    _saveTasks();
    notifyListeners();
  }

  void updateTask(String id, String title) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = Task(id: id, title: title);
      _saveTasks();
      notifyListeners();
    }
  }

  void completeTask(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks.removeAt(index);
      _completedTasks.add(task);
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    _saveTasks();
    notifyListeners();
  }

  void deleteCompletedTask(String id) {
    _completedTasks.removeWhere((task) => task.id == id);
    _saveTasks();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    prefs.setString('language', lang);
    notifyListeners();
  }
}

class Task {
  final String id;
  final String title;

  Task({required this.id, required this.title});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
    );
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: getText('appTitle', appState.language),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: appState.themeMode,
      locale: Locale(appState.language),
      supportedLocales: const [
        Locale('cs'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;

    final screens = [
      TaskListScreen(
        tasks: appState.tasks,
        onAddTask: (title) => appState.addTask(title),
        onUpdateTask: (id, title) => appState.updateTask(id, title),
        onCompleteTask: (id) => appState.completeTask(id),
        onDeleteTask: (id) => appState.deleteTask(id),
      ),
      CompletedTasksScreen(
        tasks: appState.completedTasks,
        onDeleteTask: (id) => appState.deleteCompletedTask(id),
      ),
      SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(getText('appTitle', lang)),
        elevation: 2,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.task),
            label: getText('activeTasksTab', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt),
            label: getText('completedTasksTab', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: getText('settingsTab', lang),
          ),
        ],
      ),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  final List<Task> tasks;
  final Function(String) onAddTask;
  final Function(String, String) onUpdateTask;
  final Function(String) onCompleteTask;
  final Function(String) onDeleteTask;

  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onCompleteTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppState>(context).language;

    return Column(
      children: [
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    getText('noTasks', lang),
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskItem(
                      task: task,
                      onUpdate: onUpdateTask,
                      onComplete: onCompleteTask,
                      onDelete: onDeleteTask,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(getText('addTask', lang)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              _showAddTaskDialog(context, lang, onAddTask);
            },
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog(
      BuildContext context, String lang, Function(String) onAddTask) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getText('addNewTask', lang)),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: getText('taskTitle', lang),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(getText('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              final title = textController.text.trim();
              if (title.isNotEmpty) {
                onAddTask(title);
                Navigator.pop(context);
              }
            },
            child: Text(getText('add', lang)),
          ),
        ],
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final Task task;
  final Function(String, String) onUpdate;
  final Function(String) onComplete;
  final Function(String) onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppState>(context).language;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          task.title,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showEditTaskDialog(context, lang);
              },
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {
                onComplete(task.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                onDelete(task.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, String lang) {
    final textController = TextEditingController(text: task.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getText('editTask', lang)),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: getText('taskTitle', lang),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(getText('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              final title = textController.text.trim();
              if (title.isNotEmpty) {
                onUpdate(task.id, title);
                Navigator.pop(context);
              }
            },
            child: Text(getText('save', lang)),
          ),
        ],
      ),
    );
  }
}

class CompletedTasksScreen extends StatelessWidget {
  final List<Task> tasks;
  final Function(String) onDeleteTask;

  const CompletedTasksScreen({
    super.key,
    required this.tasks,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppState>(context).language;

    return tasks.isEmpty
        ? Center(
            child: Text(
              getText('noCompletedTasks', lang),
              style: const TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      onDeleteTask(task.id);
                    },
                  ),
                ),
              );
            },
          );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getText('language', lang),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'cs',
                      label: Text('Čeština'),
                    ),
                    ButtonSegment(
                      value: 'en',
                      label: Text('English'),
                    ),
                  ],
                  selected: {appState.language},
                  onSelectionChanged: (Set<String> selection) {
                    appState.setLanguage(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getText('theme', lang),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(getText('lightTheme', lang)),
                      icon: const Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(getText('darkTheme', lang)),
                      icon: const Icon(Icons.dark_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(getText('systemTheme', lang)),
                      icon: const Icon(Icons.settings_system_daydream),
                    ),
                  ],
                  selected: {appState.themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    appState.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  getText('thankYou', lang),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  getText('appDescription', lang),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        _launchUrl('https://github.com/Parek-ke-snidani');
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.code, size: 32),
                          SizedBox(height: 8),
                          Text('GitHub'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    InkWell(
                      onTap: () {
                        _launchUrl('https://buymeacoffee.com/pseudocereal');
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.coffee, size: 32),
                          SizedBox(height: 8),
                          Text('Buy Me a Coffee'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}

// Textové řetězce pro lokalizaci
String getText(String key, String language) {
  final translations = {
    'cs': {
      'appTitle': 'Úkoly',
      'activeTasksTab': 'Aktivní',
      'completedTasksTab': 'Dokončené',
      'settingsTab': 'Nastavení',
      'addTask': 'Přidat cíl',
      'addNewTask': 'Přidat nový cíl',
      'editTask': 'Upravit úkol',
      'taskTitle': 'Název úkolu',
      'cancel': 'Zrušit',
      'add': 'Přidat',
      'save': 'Uložit',
      'noTasks': 'Žádné cíle. Přidejte nový!',
      'noCompletedTasks': 'Žádné dokončené cíle',
      'language': 'Jazyk',
      'theme': 'Vzhled aplikace',
      'lightTheme': 'Světlý',
      'darkTheme': 'Tmavý',
      'systemTheme': 'Systémový',
      'thankYou': 'Díky za používání aplikace!',
      'appDescription':
          'Tato aplikace vám pomáhá udržet přehled o vašich cílech a zvyšovat motivaci.',
    },
    'en': {
      'appTitle': 'Tasks',
      'activeTasksTab': 'Active',
      'completedTasksTab': 'Completed',
      'settingsTab': 'Settings',
      'addTask': 'Add Task',
      'addNewTask': 'Add New goal',
      'editTask': 'Edit Task',
      'taskTitle': 'Task Title',
      'cancel': 'Cancel',
      'add': 'Add',
      'save': 'Save',
      'noTasks': 'No goals. Add a new one!',
      'noCompletedTasks': 'No completed goals',
      'language': 'Language',
      'theme': 'App Theme',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'systemTheme': 'System',
      'thankYou': 'Thank you for using the app!',
      'appDescription':
          'This app helps you keep track of your tasks and increase motivation.',
    },
  };

  return translations[language]?[key] ?? translations['en']?[key] ?? key;
}
