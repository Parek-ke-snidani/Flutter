import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math'; // For max function in bar chart y-axis
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

// IMPORTANT: After setting up ARB files and l10n.yaml, run `flutter gen-l10n`
// This will generate the AppLocalizations file.
// The import path might vary slightly based on your project structure/Flutter version.
// Common paths are:
// import 'package:your_project_name/generated/app_localizations.dart';
// import 'package:your_project_name/.dart_tool/flutter_gen/gen_l10n/app_localizations.dart';
// For this example, we'll assume a common generated path:
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Generated file
import 'package:flutter_localizations/flutter_localizations.dart';

// Unique ID generator
const uuid = Uuid();

// Enum for Report Time Frames
enum ReportTimeFrame { week, month, year, all }

extension ReportTimeFrameExtension on ReportTimeFrame {
  String displayName(BuildContext context) {
    // Added BuildContext
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case ReportTimeFrame.week:
        return loc.timeFrame1Week;
      case ReportTimeFrame.month:
        return loc.timeFrame1Month;
      case ReportTimeFrame.year:
        return loc.timeFrame1Year;
      case ReportTimeFrame.all:
        return loc.timeFrameAllTime;
    }
  }
}

// --- Settings Notifier ---
class SettingsNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  MaterialColor _primaryColor = Colors.teal;
  Locale _locale = const Locale('en'); // Default language Locale

  static const String _themeModeKey = 'themeMode';
  static const String _primaryColorKey = 'primaryColor';
  static const String _languageCodeKey =
      'languageCode'; // Stores language code string

  ThemeMode get themeMode => _themeMode;
  MaterialColor get primaryColor => _primaryColor;
  Locale get locale => _locale; // Getter for Locale

  final Map<String, MaterialColor> _availableColors = {
    'Teal': Colors.teal,
    'Blue': Colors.blue,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
    'Green': Colors.green,
    'Red': Colors.red,
  };

  Map<String, MaterialColor> get availableColors => _availableColors;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Load ThemeMode
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load PrimaryColor
    final colorName = prefs.getString(_primaryColorKey);
    _primaryColor = _availableColors[colorName] ?? Colors.teal;

    // Load Language
    final langCode = prefs.getString(_languageCodeKey) ?? 'en';
    _locale = Locale(langCode);

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.light) {
      await prefs.setString(_themeModeKey, 'light');
    } else if (_themeMode == ThemeMode.dark) {
      await prefs.setString(_themeModeKey, 'dark');
    } else {
      await prefs.setString(_themeModeKey, 'system');
    }

    final colorName =
        _availableColors.entries
            .firstWhere(
              (entry) => entry.value == _primaryColor,
              orElse: () => _availableColors.entries.first,
            )
            .key;
    await prefs.setString(_primaryColorKey, colorName);
    await prefs.setString(
      _languageCodeKey,
      _locale.languageCode,
    ); // Save language code string
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveSettings();
      notifyListeners();
    }
  }

  void setPrimaryColor(MaterialColor color) {
    if (_primaryColor != color) {
      _primaryColor = color;
      _saveSettings();
      notifyListeners();
    }
  }

  void setLocale(Locale newLocale) {
    // Changed method name and parameter type
    if (_locale != newLocale) {
      _locale = newLocale;
      _saveSettings();
      notifyListeners();
    }
  }
}

// --- Data Models ---
class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.toJson(),
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'],
    title: json['title'],
    amount: json['amount'],
    date: DateTime.parse(json['date']),
    category: Category.fromJson(json['category']),
  );
}

class Category {
  final String
  name; // This name will be used as a key for localization if needed
  final IconData icon;
  final Color color;

  const Category({required this.name, required this.icon, required this.color});

  // Helper to get localized name
  String getLocalizedName(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // This requires category names to be keys in ARB files or a mapping
    // For simplicity, we'll assume predefinedCategories.name are simple keys
    // or we can hardcode a switch here for now.
    // A more robust solution would be to have keys like "categoryFood", "categoryTransport" in ARB.
    // For now, let's return the name directly, assuming it's simple enough or already localized if passed.
    // If you want to localize category names like "Food", "Transport", they need to be in ARB files
    // and you'd look them up: e.g. loc.categoryFood, loc.categoryTransport
    // For this example, we'll keep predefined names as is, assuming they are universal or simple.
    // If you want to localize them, you'd do:
    // switch (name) {
    //   case 'Food': return loc.categoryFood; // Assuming categoryFood is in ARB
    //   // ... etc.
    // }
    return name; // Placeholder: For truly localized category names, this needs more setup.
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon_code_point': icon.codePoint,
    'icon_font_family': icon.fontFamily,
    'icon_font_package': icon.fontPackage,
    'color': color.value,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'],
    icon: IconData(
      json['icon_code_point'],
      fontFamily: json['icon_font_family'],
      fontPackage: json['icon_font_package'],
    ),
    color: Color(json['color']),
  );

  static List<Category> predefinedCategories = [
    // Names here are used as keys or direct display. For localization, these should be keys.
    const Category(name: 'Food', icon: Icons.fastfood, color: Colors.orange),
    const Category(
      name: 'Transport',
      icon: Icons.directions_car,
      color: Colors.blue,
    ),
    const Category(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Colors.pink,
    ),
    const Category(name: 'Bills', icon: Icons.receipt, color: Colors.green),
    const Category(
      name: 'Entertainment',
      icon: Icons.movie,
      color: Colors.purple,
    ),
    const Category(name: 'Health', icon: Icons.healing, color: Colors.red),
    const Category(name: 'Education', icon: Icons.school, color: Colors.teal),
    const Category(name: 'Other', icon: Icons.category, color: Colors.grey),
  ];

  static Category findByName(String name) {
    return predefinedCategories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => predefinedCategories.last,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// --- Main Application ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsNotifier(),
      child: const FinTrackApp(),
    ),
  );
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  ThemeData _buildThemeData(SettingsNotifier settings, Brightness brightness) {
    final baseTheme =
        brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final primaryColor = settings.primaryColor;
    final TextTheme defaultTextTheme =
        brightness == Brightness.dark
            ? Typography.whiteMountainView
            : Typography.blackMountainView;

    return baseTheme.copyWith(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor.shade700,
        secondary: Colors.amber.shade700,
      ),
      scaffoldBackgroundColor:
          brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.latoTextTheme(defaultTextTheme).copyWith(
        bodyLarge: GoogleFonts.montserrat(
          textStyle: defaultTextTheme.bodyLarge,
        ),
        displayLarge: GoogleFonts.montserrat(
          textStyle: defaultTextTheme.displayLarge,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color:
              brightness == Brightness.dark
                  ? primaryColor.shade200
                  : primaryColor.shade800,
        ),
        titleMedium: GoogleFonts.montserrat(
          textStyle: defaultTextTheme.titleMedium,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.lato(
          // For dropdowns in settings
          textStyle: defaultTextTheme.titleSmall,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor.shade700,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor:
            brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
        selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.montserrat(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.shade700, width: 2),
        ),
        labelStyle: GoogleFonts.montserrat(color: primaryColor.shade700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor:
            brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color:
              brightness == Brightness.dark
                  ? primaryColor.shade200
                  : primaryColor.shade800,
        ),
        contentTextStyle: GoogleFonts.lato(fontSize: 16),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        selectedColor: Colors.white,
        color: primaryColor,
        fillColor: primaryColor.withOpacity(0.8),
        borderColor: primaryColor,
        selectedBorderColor: primaryColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        // Theme for DropdownButton
        textStyle: GoogleFonts.lato(
          color: brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsNotifier>(context);
    return MaterialApp(
      title:
          'FinTrack', // This will be overridden by AppLocalizations if available on first screen
      theme: _buildThemeData(settings, Brightness.light),
      darkTheme: _buildThemeData(settings, Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale, // Set the locale from SettingsNotifier
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: const ExpenseTrackerHomePage(),
      // Add onGenerateTitle for dynamic app title based on locale
      onGenerateTitle: (BuildContext context) {
        return AppLocalizations.of(context)?.appTitle ?? 'FinTrack';
      },
    );
  }
}

class ExpenseTrackerHomePage extends StatefulWidget {
  const ExpenseTrackerHomePage({super.key});

  @override
  State<ExpenseTrackerHomePage> createState() => _ExpenseTrackerHomePageState();
}

class _ExpenseTrackerHomePageState extends State<ExpenseTrackerHomePage> {
  int _selectedIndex = 0;
  List<Expense> _expenses = [];

  Category? _selectedReportCategory;
  ReportTimeFrame _selectedReportTimeFrame = ReportTimeFrame.all;

  static const String _expensesKey = 'expenses_data';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesString = prefs.getString(_expensesKey);
    if (expensesString != null) {
      final List<dynamic> expensesJson = jsonDecode(expensesString);
      if (mounted) {
        // Check if widget is still in the tree
        setState(() {
          _expenses =
              expensesJson.map((json) => Expense.fromJson(json)).toList();
          _expenses.sort((a, b) => b.date.compareTo(a.date));
        });
      }
    }
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String expensesString = jsonEncode(
      _expenses.map((expense) => expense.toJson()).toList(),
    );
    await prefs.setString(_expensesKey, expensesString);
  }

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    });
    _saveExpenses();
  }

  void _deleteExpense(String id) {
    final currentContext = context; // Capture context
    setState(() {
      _expenses.removeWhere((expense) => expense.id == id);
    });
    _saveExpenses();
    if (currentContext.mounted) {
      // Use captured context
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(currentContext)!.expenseDeleted,
            style: GoogleFonts.lato(),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Expense> _getFilteredExpenses() {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (_selectedReportTimeFrame) {
      case ReportTimeFrame.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ReportTimeFrame.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case ReportTimeFrame.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case ReportTimeFrame.all:
      default:
        startDate = DateTime(2000);
        break;
    }

    return _expenses.where((expense) {
      final bool matchesCategory =
          _selectedReportCategory == null ||
          expense.category.name == _selectedReportCategory!.name;
      final bool matchesTimeFrame =
          !expense.date.isBefore(startDate) &&
          expense.date.isBefore(now.add(const Duration(days: 1)));
      return matchesCategory && matchesTimeFrame;
    }).toList();
  }

  Widget _buildHomeScreen() {
    final settings = Provider.of<SettingsNotifier>(context, listen: false);
    final loc = AppLocalizations.of(context)!; // Localization instance
    final now = DateTime.now();
    final currentMonthExpenses = _expenses.where(
      (exp) => exp.date.year == now.year && exp.date.month == now.month,
    );
    final totalCurrentMonth = currentMonthExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final recentExpenses = _expenses.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.welcomeBack,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: settings.primaryColor.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMMd(
              loc.localeName,
            ).format(now), // Localized date format
            style: GoogleFonts.lato(
              fontSize: 16,
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.7) ??
                  Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            color: settings.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.thisMonthsSpending,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: settings.primaryColor.shade700,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: loc.localeName,
                          ) // Localized currency
                          .format(totalCurrentMonth),
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: settings.primaryColor.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: settings.primaryColor.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.recentTransactions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 20,
              color: settings.primaryColor.shade700,
            ),
          ),
          const SizedBox(height: 10),
          if (recentExpenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.noTransactionsYet,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentExpenses.length,
              itemBuilder: (context, index) {
                final expense = recentExpenses[index];
                return _buildExpenseListItem(expense, isDetailed: false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesListScreen() {
    final loc = AppLocalizations.of(context)!;
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              loc.noExpensesRecordedYet,
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.addNewExpensePrompt,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Slidable(
          key: ValueKey(expense.id),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _deleteExpense(expense.id),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: loc.delete,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          child: _buildExpenseListItem(expense, isDetailed: true),
        );
      },
    );
  }

  Widget _buildExpenseListItem(Expense expense, {required bool isDetailed}) {
    final settings = Provider.of<SettingsNotifier>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: expense.category.color.withOpacity(0.2),
          child: Icon(
            expense.category.icon,
            color: expense.category.color,
            size: 24,
          ),
        ),
        title: Text(
          expense.title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          // Category name localization would go here if implemented in Category.getLocalizedName
          '${expense.category.getLocalizedName(context)} • ${DateFormat.yMd(loc.localeName).format(expense.date)}',
          style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
        ),
        trailing: Text(
          NumberFormat.currency(locale: loc.localeName).format(expense.amount),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color:
                expense.amount >= 0 ? settings.primaryColor : Colors.redAccent,
          ),
        ),
        onTap:
            isDetailed
                ? () {
                  _showAddExpenseModal(existingExpense: expense);
                }
                : null,
      ),
    );
  }

  Widget _buildReportsScreen() {
    final settings = Provider.of<SettingsNotifier>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final List<Expense> filteredExpenses = _getFilteredExpenses();

    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              loc.notEnoughDataForReports,
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.addExpensesForPatterns,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Map<String, double> categorySpending = {};
    double totalExpensesForPie = 0;
    for (var expense in filteredExpenses) {
      categorySpending.update(
        expense.category.name, // Using raw name as key
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
      totalExpensesForPie += expense.amount;
    }
    if (totalExpensesForPie == 0) totalExpensesForPie = 1;

    List<PieChartSectionData> pieChartSections =
        categorySpending.entries.map((entry) {
          final category = Category.findByName(entry.key);
          final percentage = (entry.value / totalExpensesForPie * 100);
          return PieChartSectionData(
            color: category.color,
            value: entry.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 100,
            titleStyle: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: null,
            badgePositionPercentageOffset: .98,
          );
        }).toList();

    Map<String, double> timeSeriesSpending = {};
    String barChartTitleKey =
        "spendingTrend"; // Placeholder, will be set in switch
    DateTime now = DateTime.now();
    double maxTimeSeriesSpending = 0;

    switch (_selectedReportTimeFrame) {
      case ReportTimeFrame.week:
        barChartTitleKey = loc.last7DaysTrend;
        for (int i = 6; i >= 0; i--) {
          DateTime day = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i));
          String dayKey = DateFormat.E(loc.localeName).format(day);
          timeSeriesSpending[dayKey] = 0.0;
        }
        for (var expense in filteredExpenses) {
          String dayKey = DateFormat.E(loc.localeName).format(expense.date);
          if (timeSeriesSpending.containsKey(dayKey)) {
            timeSeriesSpending.update(
              dayKey,
              (value) => value + expense.amount,
            );
          }
        }
        break;
      case ReportTimeFrame.month:
        barChartTitleKey = loc.last30DaysTrendDaily;
        for (int i = 29; i >= 0; i--) {
          DateTime day = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i));
          String dayKey = DateFormat.Md(loc.localeName).format(day);
          timeSeriesSpending[dayKey] = 0.0;
        }
        for (var expense in filteredExpenses) {
          String dayKey = DateFormat.Md(loc.localeName).format(expense.date);
          if (timeSeriesSpending.containsKey(dayKey)) {
            timeSeriesSpending.update(
              dayKey,
              (value) => value + expense.amount,
            );
          }
        }
        break;
      case ReportTimeFrame.year:
        barChartTitleKey = loc.last12MonthsTrend;
        for (int i = 11; i >= 0; i--) {
          DateTime monthDateTime = DateTime(now.year, now.month - i, 1);
          String monthKey = DateFormat.MMM(
            loc.localeName,
          ).format(monthDateTime);
          timeSeriesSpending[monthKey] = 0.0;
        }
        for (var expense in filteredExpenses) {
          String monthKey = DateFormat.MMM(loc.localeName).format(expense.date);
          if (timeSeriesSpending.containsKey(monthKey)) {
            timeSeriesSpending.update(
              monthKey,
              (value) => value + expense.amount,
            );
          }
        }
        break;
      case ReportTimeFrame.all:
        barChartTitleKey = loc.overallTrendYearly;
        if (filteredExpenses.isNotEmpty) {
          int firstYear = filteredExpenses.map((e) => e.date.year).reduce(min);
          int lastYear = filteredExpenses.map((e) => e.date.year).reduce(max);
          for (int year = firstYear; year <= lastYear; year++) {
            timeSeriesSpending[year.toString()] = 0.0;
          }
          for (var expense in filteredExpenses) {
            timeSeriesSpending.update(
              expense.date.year.toString(),
              (value) => value + expense.amount,
            );
          }
        }
        break;
    }

    if (timeSeriesSpending.isNotEmpty) {
      maxTimeSeriesSpending = timeSeriesSpending.values.fold(
        0.0,
        (prev, element) => element > prev ? element : prev,
      );
    }
    if (maxTimeSeriesSpending == 0) maxTimeSeriesSpending = 10;

    List<BarChartGroupData> barChartGroups = [];
    int x = 0;
    timeSeriesSpending.forEach((key, amount) {
      barChartGroups.add(
        BarChartGroupData(
          x: x++,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: settings.primaryColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    });

    double totalSpentInFiltered = filteredExpenses.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    String mostSpentCategoryInFiltered = "";
    if (categorySpending.isNotEmpty) {
      mostSpentCategoryInFiltered =
          categorySpending.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.filters,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 20,
              color: settings.primaryColor.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Category?>(
                  value: _selectedReportCategory,
                  decoration: InputDecoration(
                    labelText: loc.category,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 12.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  hint: Text(loc.allCategories, style: GoogleFonts.lato()),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<Category?>(
                      value: null,
                      child: Text(loc.allCategories, style: GoogleFonts.lato()),
                    ),
                    ...Category.predefinedCategories.map((Category category) {
                      return DropdownMenuItem<Category?>(
                        value: category,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              category.icon,
                              color: category.color,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category.getLocalizedName(context),
                                style: GoogleFonts.lato(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (Category? newValue) {
                    setState(() {
                      _selectedReportCategory = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: ToggleButtons(
              isSelected:
                  ReportTimeFrame.values
                      .map((e) => e == _selectedReportTimeFrame)
                      .toList(),
              onPressed: (int index) {
                setState(() {
                  _selectedReportTimeFrame = ReportTimeFrame.values[index];
                });
              },
              constraints: BoxConstraints(
                minHeight: 40.0,
                minWidth:
                    (MediaQuery.of(context).size.width - 48) /
                    ReportTimeFrame.values.length,
              ),
              children:
                  ReportTimeFrame.values.map((timeFrame) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        timeFrame.displayName(context),
                        style: GoogleFonts.lato(fontSize: 13),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          if (filteredExpenses.isEmpty && _expenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_off_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.noExpensesMatchFilters,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredExpenses.isNotEmpty) ...[
            Text(
              loc.spendingSummary,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 24,
                color: settings.primaryColor.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.totalSpentFiltered(
                        NumberFormat.currency(
                          locale: loc.localeName,
                        ).format(totalSpentInFiltered),
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: settings.primaryColor.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (mostSpentCategoryInFiltered.isNotEmpty)
                      Text(
                        loc.mostSpentOn(
                          Category.findByName(
                            mostSpentCategoryInFiltered,
                          ).getLocalizedName(context),
                        ),
                        style: GoogleFonts.lato(fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      loc.numberOfTransactions(filteredExpenses.length),
                      style: GoogleFonts.lato(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.byCategory,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                color: settings.primaryColor.shade700,
              ),
            ),
            SizedBox(
              height: 250,
              child:
                  pieChartSections.isEmpty
                      ? _emptyChartPlaceholder(loc.noCategoryData)
                      : PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 10),
            _buildLegend(categorySpending),
            const SizedBox(height: 24),
            Text(
              barChartTitleKey,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                color: settings.primaryColor.shade700,
              ),
            ),
            SizedBox(
              height: 250,
              child:
                  barChartGroups.isEmpty
                      ? _emptyChartPlaceholder(loc.noTrendData)
                      : BarChart(
                        BarChartData(
                          barGroups: barChartGroups,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final titles =
                                      timeSeriesSpending.keys.toList();
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < titles.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        titles[value.toInt()],
                                        style: GoogleFonts.lato(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0 && maxTimeSeriesSpending > 0)
                                    return Text(
                                      NumberFormat.compactCurrency(
                                        locale: loc.localeName,
                                        symbol: '',
                                      ).format(0),
                                      style: GoogleFonts.lato(fontSize: 10),
                                    );
                                  if (value == 0) return const Text('');

                                  final interval =
                                      (maxTimeSeriesSpending / 4)
                                          .ceilToDouble();
                                  if (interval > 0 &&
                                      (value == meta.max ||
                                          value % interval == 0)) {
                                    return Text(
                                      NumberFormat.compactCurrency(
                                        locale: loc.localeName,
                                        symbol: '',
                                      ).format(value),
                                      style: GoogleFonts.lato(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                (maxTimeSeriesSpending / 4).ceilToDouble() > 0
                                    ? (maxTimeSeriesSpending / 4).ceilToDouble()
                                    : 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.shade300,
                                strokeWidth: 0.5,
                              );
                            },
                          ),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => Colors.blueGrey.shade800,
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                String timeKey = "";
                                final titles = timeSeriesSpending.keys.toList();
                                if (group.x.toInt() >= 0 &&
                                    group.x.toInt() < titles.length) {
                                  timeKey = titles[group.x.toInt()];
                                }
                                return BarTooltipItem(
                                  '$timeKey\n',
                                  GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: NumberFormat.currency(
                                        locale: loc.localeName,
                                      ).format(rod.toY),
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
            ),
          ] else if (_expenses.isNotEmpty && filteredExpenses.isEmpty)
            Container(),
        ],
      ),
    );
  }

  Widget _emptyChartPlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, color: Colors.grey.shade300, size: 50),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, double> categorySpending) {
    if (categorySpending.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children:
          categorySpending.keys.map((categoryName) {
            final category = Category.findByName(categoryName);
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(category.icon, size: 18, color: category.color),
              ),
              label: Text(
                category.getLocalizedName(context),
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? category.color
                          : category.color,
                ),
              ),
              backgroundColor: category.color.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: category.color.withOpacity(0.4)),
              ),
            );
          }).toList(),
    );
  }

  void _showAddExpenseModal({Expense? existingExpense}) {
    final formKey = GlobalKey<FormState>();
    final loc = AppLocalizations.of(context)!;
    String title = existingExpense?.title ?? '';
    double? amount = existingExpense?.amount;
    DateTime selectedDate = existingExpense?.date ?? DateTime.now();
    Category selectedCategory = Category.predefinedCategories.firstWhere(
      (cat) => cat.name == existingExpense?.category.name,
      orElse: () => Category.predefinedCategories.first,
    );

    bool isEditing = existingExpense != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        final settings = Provider.of<SettingsNotifier>(context, listen: false);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Text(
                          isEditing
                              ? loc.editExpenseModalTitle
                              : loc.addExpenseModalTitle,
                          style: Theme.of(
                            context,
                          ).textTheme.displayLarge?.copyWith(
                            fontSize: 22,
                            color: settings.primaryColor.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextFormField(
                        initialValue: title,
                        decoration: InputDecoration(
                          labelText: loc.titleDescription,
                          hintText: loc.titleHint,
                        ),
                        style: GoogleFonts.lato(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.pleaseEnterTitle;
                          }
                          return null;
                        },
                        onSaved: (value) => title = value!.trim(),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue: amount?.toStringAsFixed(2),
                        decoration: InputDecoration(
                          labelText: loc.amount,
                          prefixText:
                              NumberFormat.simpleCurrency(
                                locale: loc.localeName,
                              ).currencySymbol,
                          hintText: loc.amountHint,
                        ),
                        style: GoogleFonts.lato(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.pleaseEnterAmount;
                          }
                          final parsedAmount = double.tryParse(
                            value.replaceAll(',', '.'),
                          ); // Handle comma as decimal separator
                          if (parsedAmount == null) {
                            return loc.pleaseEnterValidNumber;
                          }
                          if (parsedAmount <= 0) {
                            return loc.amountMustBePositive;
                          }
                          return null;
                        },
                        onSaved:
                            (value) =>
                                amount = double.parse(
                                  value!.replaceAll(',', '.'),
                                ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        decoration: InputDecoration(labelText: loc.category),
                        dropdownColor: Theme.of(context).cardColor,
                        items:
                            Category.predefinedCategories.map((
                              Category category,
                            ) {
                              return DropdownMenuItem<Category>(
                                value: category,
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      category.icon,
                                      color: category.color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      category.getLocalizedName(context),
                                      style: GoogleFonts.lato(fontSize: 15),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (Category? newValue) {
                          if (newValue != null) {
                            modalSetState(() {
                              selectedCategory = newValue;
                            });
                          }
                        },
                        validator:
                            (value) =>
                                value == null ? loc.pleaseSelectCategory : null,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.date(
                              DateFormat.yMMMMd(
                                loc.localeName,
                              ).format(selectedDate),
                            ),
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(
                              Icons.edit_calendar_outlined,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            label: Text(
                              loc.changeDate,
                              style: GoogleFonts.lato(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(DateTime.now().year - 5),
                                lastDate: DateTime.now(),
                                locale:
                                    settings
                                        .locale, // Pass locale to DatePicker
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: Theme.of(
                                        context,
                                      ).colorScheme.copyWith(
                                        primary: settings.primaryColor,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != selectedDate) {
                                modalSetState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          isEditing ? loc.saveChanges : loc.addExpenseButton,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            final newOrUpdatedExpense = Expense(
                              id: existingExpense?.id,
                              title: title,
                              amount: amount!,
                              date: selectedDate,
                              category: selectedCategory,
                            );
                            if (isEditing) {
                              _deleteExpense(existingExpense!.id);
                            }
                            _addExpense(newOrUpdatedExpense);
                            Navigator.of(ctx).pop();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getAppBarTitle(
    BuildContext context,
    int index,
    SettingsNotifier settings,
  ) {
    final loc = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return loc.dashboardTitle;
      case 1:
        return loc.allExpenses;
      case 2:
        return loc.spendingReports;
      default:
        return loc.appTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsNotifier>(context, listen: false);
    final loc = AppLocalizations.of(context)!; // For BottomNavigationBar labels
    final List<Widget> widgetOptions = <Widget>[
      _buildHomeScreen(),
      _buildExpensesListScreen(),
      _buildReportsScreen(),
    ];

    Color appBarForegroundColor =
        ThemeData.estimateBrightnessForColor(
                  _selectedIndex == 0
                      ? Theme.of(context).scaffoldBackgroundColor
                      : settings.primaryColor.shade700,
                ) ==
                Brightness.dark
            ? Colors.white
            : Colors.black;

    // For dashboard, title color should be primary, regardless of scaffold bg brightness
    Color dashboardTitleColor =
        Theme.of(context).brightness == Brightness.dark
            ? settings.primaryColor.shade200
            : settings.primaryColor.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(context, _selectedIndex, settings)),
        elevation: _selectedIndex == 0 ? 0 : 2,
        backgroundColor:
            _selectedIndex == 0
                ? Theme.of(context).scaffoldBackgroundColor
                : settings.primaryColor.shade700,
        foregroundColor:
            _selectedIndex == 0 ? dashboardTitleColor : appBarForegroundColor,
        titleTextStyle:
            _selectedIndex == 0
                ? GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: dashboardTitleColor,
                )
                : GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: appBarForegroundColor,
                ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color:
                  _selectedIndex == 0
                      ? dashboardTitleColor
                      : appBarForegroundColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: loc.settings,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            activeIcon: const Icon(Icons.home),
            label: loc.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt_outlined),
            activeIcon: const Icon(Icons.list_alt),
            label: loc.expenses,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: loc.reports,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton:
          _selectedIndex == 0 || _selectedIndex == 1
              ? FloatingActionButton.extended(
                onPressed: () => _showAddExpenseModal(),
                icon: const Icon(Icons.add, size: 24),
                label: Text(
                  loc.addNew,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                elevation: 4,
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- Settings Screen ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsNotifier>(context);
    final loc = AppLocalizations.of(context)!;
    final currentPrimaryColorName =
        settings.availableColors.entries
            .firstWhere(
              (entry) => entry.value == settings.primaryColor,
              orElse: () => settings.availableColors.entries.first,
            )
            .key;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings, style: GoogleFonts.montserrat()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text(
            loc.appearance,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: settings.primaryColor.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(loc.themeMode, style: GoogleFonts.lato()),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              dropdownColor: Theme.of(context).cardColor,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(
                    loc.systemDefault,
                    style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(
                    loc.lightMode,
                    style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(
                    loc.darkMode,
                    style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  settings.setThemeMode(mode);
                }
              },
            ),
          ),
          ListTile(
            title: Text(loc.primaryColor, style: GoogleFonts.lato()),
            trailing: DropdownButton<String>(
              value: currentPrimaryColorName,
              dropdownColor: Theme.of(context).cardColor,
              items:
                  settings.availableColors.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: GoogleFonts.lato(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (String? colorName) {
                if (colorName != null &&
                    settings.availableColors[colorName] != null) {
                  settings.setPrimaryColor(
                    settings.availableColors[colorName]!,
                  );
                }
              },
            ),
          ),
          const Divider(height: 32, thickness: 1),
          Text(
            loc.language,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: settings.primaryColor.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(loc.appLanguage, style: GoogleFonts.lato()),
            trailing: DropdownButton<Locale>(
              // Changed to Locale
              value: settings.locale,
              dropdownColor: Theme.of(context).cardColor,
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(
                    loc.english,
                    style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: const Locale('cs'),
                  child: Text(
                    loc.czech,
                    style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  settings.setLocale(newLocale);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              loc.languageChangeDisclaimer,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
