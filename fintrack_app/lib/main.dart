import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math'; // For max function in bar chart y-axis
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// Unique ID generator
const uuid = Uuid();

// Enum for Report Time Frames
enum ReportTimeFrame { week, month, year, all }

extension ReportTimeFrameExtension on ReportTimeFrame {
  String get displayName {
    switch (this) {
      case ReportTimeFrame.week:
        return '1 Week';
      case ReportTimeFrame.month:
        return '1 Month';
      case ReportTimeFrame.year:
        return '1 Year';
      case ReportTimeFrame.all:
        return 'All Time';
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

  // For JSON serialization/deserialization
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
  final String name;
  final IconData icon;
  final Color color; // Added color for better visuals in charts/lists

  const Category({required this.name, required this.icon, required this.color});

  // For JSON serialization/deserialization
  Map<String, dynamic> toJson() => {
    'name': name,
    // Storing icon data as code point and font family
    'icon_code_point': icon.codePoint,
    'icon_font_family': icon.fontFamily,
    'icon_font_package': icon.fontPackage,
    'color': color.value, // Store color as int
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

  // Predefined categories
  static List<Category> predefinedCategories = [
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
    ); // Default to 'Other'
  }

  // Override equals and hashCode for DropdownButton comparison
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
  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      title: 'FinTrack',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        // Use GoogleFonts
        textTheme: GoogleFonts.latoTextTheme(textTheme).copyWith(
          bodyLarge: GoogleFonts.montserrat(textStyle: textTheme.bodyLarge),
          displayLarge: GoogleFonts.montserrat(
            textStyle: textTheme.displayLarge,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
          titleMedium: GoogleFonts.montserrat(
            textStyle: textTheme.titleMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
          primary: Colors.teal.shade700,
          secondary: Colors.amber.shade700,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.teal.shade700,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.black87,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
          ),
          labelStyle: GoogleFonts.montserrat(color: Colors.teal.shade700),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
          contentTextStyle: GoogleFonts.lato(fontSize: 16),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const ExpenseTrackerHomePage(),
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

  // Report screen filters
  Category? _selectedReportCategory; // null means all categories
  ReportTimeFrame _selectedReportTimeFrame = ReportTimeFrame.all;

  // SharedPreferences key
  static const String _expensesKey = 'expenses_data';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // --- Data Persistence ---
  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesString = prefs.getString(_expensesKey);
    if (expensesString != null) {
      final List<dynamic> expensesJson = jsonDecode(expensesString);
      setState(() {
        _expenses = expensesJson.map((json) => Expense.fromJson(json)).toList();
        _expenses.sort(
          (a, b) => b.date.compareTo(a.date),
        ); // Sort once after loading
      });
    }
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String expensesString = jsonEncode(
      _expenses.map((expense) => expense.toJson()).toList(),
    );
    await prefs.setString(_expensesKey, expensesString);
  }

  // --- Expense Management ---
  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
      _expenses.sort(
        (a, b) => b.date.compareTo(a.date),
      ); // Sort by date descending
    });
    _saveExpenses();
  }

  void _deleteExpense(String id) {
    // Store the context before the async gap.
    final currentContext = context;
    setState(() {
      _expenses.removeWhere((expense) => expense.id == id);
    });
    _saveExpenses();
    // Check if the widget is still mounted before showing SnackBar
    if (currentContext.mounted) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Expense deleted', style: GoogleFonts.lato()),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- UI Navigation ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Helper for Report Filters ---
  List<Expense> _getFilteredExpenses() {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (_selectedReportTimeFrame) {
      case ReportTimeFrame.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ReportTimeFrame.month:
        // Last 30 days for simplicity, or could be current calendar month
        startDate = now.subtract(const Duration(days: 30));
        break;
      case ReportTimeFrame.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case ReportTimeFrame.all:
      default:
        startDate = DateTime(2000); // A very early date for all time
        break;
    }

    return _expenses.where((expense) {
      final bool matchesCategory =
          _selectedReportCategory == null ||
          expense.category.name == _selectedReportCategory!.name;
      final bool matchesTimeFrame =
          !expense.date.isBefore(startDate) &&
          expense.date.isBefore(
            now.add(const Duration(days: 1)),
          ); // ensure up to current day
      return matchesCategory && matchesTimeFrame;
    }).toList();
  }

  // --- Widgets for each tab ---
  Widget _buildHomeScreen() {
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
            'Welcome Back!',
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMMd().format(now),
            style: GoogleFonts.lato(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Added Expanded to prevent overflow if text is long
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Month\'s Spending',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_US',
                            symbol: '\$',
                          ).format(totalCurrentMonth),
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 20,
              color: Theme.of(context).colorScheme.primary,
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
                      'No transactions yet.',
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
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No expenses recorded yet.',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the "Add New" button to add your first expense!',
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
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
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
                label: 'Delete',
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
          '${expense.category.name} • ${DateFormat.yMd().format(expense.date)}',
          style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
        ),
        trailing: Text(
          NumberFormat.currency(
            locale: 'en_US',
            symbol: '\$',
          ).format(expense.amount),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color:
                expense.amount >= 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.redAccent,
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
    final List<Expense> filteredExpenses = _getFilteredExpenses();

    if (_expenses.isEmpty) {
      // Check original list for overall empty state
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
              'No expenses recorded yet.',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see your spending patterns.',
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

    // Data for Pie Chart (Spending by Category) using filteredExpenses
    Map<String, double> categorySpending = {};
    double totalExpensesForPie = 0;
    for (var expense in filteredExpenses) {
      categorySpending.update(
        expense.category.name,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
      totalExpensesForPie += expense.amount;
    }
    if (totalExpensesForPie == 0)
      totalExpensesForPie = 1; // Avoid division by zero

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
            // badgeWidget: Icon(category.icon, size: 20, color: category.color.withOpacity(0.7)), // Icon removed from slice
            badgeWidget: null, // Explicitly null
            badgePositionPercentageOffset: .98,
          );
        }).toList();

    // --- Bar Chart Data Preparation ---
    Map<String, double> timeSeriesSpending = {};
    String barChartTitle = "Spending Trend";
    DateTime now = DateTime.now();
    double maxTimeSeriesSpending = 0;

    switch (_selectedReportTimeFrame) {
      case ReportTimeFrame.week:
        barChartTitle = "Last 7 Days Trend";
        for (int i = 6; i >= 0; i--) {
          DateTime day = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i));
          String dayKey = DateFormat.E().format(day); // Mon, Tue
          timeSeriesSpending[dayKey] = 0.0;
        }
        for (var expense in filteredExpenses) {
          String dayKey = DateFormat.E().format(expense.date);
          if (timeSeriesSpending.containsKey(dayKey)) {
            // Ensure key exists (it should due to prefill)
            timeSeriesSpending.update(
              dayKey,
              (value) => value + expense.amount,
            );
          }
        }
        break;
      case ReportTimeFrame.month:
        barChartTitle = "Last 30 Days Trend (Daily)";
        for (int i = 29; i >= 0; i--) {
          DateTime day = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i));
          String dayKey = DateFormat.Md().format(day); // e.g., 5/23
          timeSeriesSpending[dayKey] = 0.0;
        }
        for (var expense in filteredExpenses) {
          String dayKey = DateFormat.Md().format(expense.date);
          if (timeSeriesSpending.containsKey(dayKey)) {
            timeSeriesSpending.update(
              dayKey,
              (value) => value + expense.amount,
            );
          }
        }
        break;
      case ReportTimeFrame.year:
        barChartTitle = "Last 12 Months Trend";
        for (int i = 11; i >= 0; i--) {
          DateTime monthDateTime = DateTime(now.year, now.month - i, 1);
          String monthKey = DateFormat.MMM().format(monthDateTime); // Jan, Feb
          timeSeriesSpending[monthKey] = 0.0;
        }
        for (var expense in filteredExpenses) {
          String monthKey = DateFormat.MMM().format(expense.date);
          if (timeSeriesSpending.containsKey(monthKey)) {
            timeSeriesSpending.update(
              monthKey,
              (value) => value + expense.amount,
            );
          }
        }
        break;
      case ReportTimeFrame.all:
        barChartTitle = "Overall Trend (Yearly)";
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
    if (maxTimeSeriesSpending == 0)
      maxTimeSeriesSpending = 10; // Default for empty chart grid

    List<BarChartGroupData> barChartGroups = [];
    int x = 0;
    timeSeriesSpending.forEach((key, amount) {
      barChartGroups.add(
        BarChartGroupData(
          x: x++,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Theme.of(context).colorScheme.primary,
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
      // categorySpending is already based on filteredExpenses
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
          // --- Filter UI ---
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Category?>(
                  value: _selectedReportCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 12.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  hint: Text('All Categories', style: GoogleFonts.lato()),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<Category?>(
                      value: null, // Represents "All Categories"
                      child: Text('All Categories', style: GoogleFonts.lato()),
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
                                category.name,
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
            // Center the ToggleButtons
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
              borderRadius: BorderRadius.circular(8.0),
              selectedBorderColor: Theme.of(context).colorScheme.primary,
              selectedColor: Colors.white,
              fillColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(context).colorScheme.primary,
              constraints: BoxConstraints(
                minHeight: 40.0,
                minWidth:
                    (MediaQuery.of(context).size.width - 48) /
                    ReportTimeFrame.values.length,
              ), // Adjust width
              children:
                  ReportTimeFrame.values.map((timeFrame) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        timeFrame.displayName,
                        style: GoogleFonts.lato(fontSize: 13),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // --- End Filter UI ---
          if (filteredExpenses.isEmpty &&
              _expenses
                  .isNotEmpty) // Show if filters result in no data, but there is data overall
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
                      'No expenses match your current filters.',
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
            // Only show charts and summary if there's filtered data
            Text(
              'Spending Summary',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent (Filtered): ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(totalSpentInFiltered)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (mostSpentCategoryInFiltered.isNotEmpty)
                      Text(
                        'Most Spent On: $mostSpentCategoryInFiltered',
                        style: GoogleFonts.lato(fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Number of Transactions: ${filteredExpenses.length}',
                      style: GoogleFonts.lato(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'By Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              height: 250,
              child:
                  pieChartSections.isEmpty
                      ? _emptyChartPlaceholder(
                        "No category data for current filters",
                      )
                      : PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback: (
                              FlTouchEvent event,
                              pieTouchResponse,
                            ) {
                              //setState(() { // Example: Make sections interactive
                              // if (!event.isInterestedForInteractions ||
                              // pieTouchResponse == null ||
                              // pieTouchResponse.touchedSection == null) {
                              //   // touchedIndex = -1;
                              // return;
                              // }
                              //   // touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              //});
                            },
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 10),
            _buildLegend(
              categorySpending,
            ), // Legend uses categorySpending from filtered data
            const SizedBox(height: 24),
            Text(
              barChartTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              height: 250,
              child:
                  barChartGroups.isEmpty
                      ? _emptyChartPlaceholder(
                        "No trend data for current filters",
                      )
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
                                  if (value == 0) return const Text('');
                                  // Show labels at reasonable intervals
                                  final interval =
                                      (maxTimeSeriesSpending / 4)
                                          .ceilToDouble();
                                  if (interval > 0 &&
                                      (value == meta.max ||
                                          value % interval == 0)) {
                                    return Text(
                                      NumberFormat.compact().format(value),
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
                                        locale: 'en_US',
                                        symbol: '\$',
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
          ] // End of conditional rendering for filteredExpenses.isNotEmpty
          else if (_expenses.isNotEmpty &&
              filteredExpenses.isEmpty) // This case is now handled above
            Container(), // Should not be reached if above logic is correct
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
              label: Text(category.name, style: GoogleFonts.lato(fontSize: 13)),
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

  // --- Add/Edit Expense Modal ---
  void _showAddExpenseModal({Expense? existingExpense}) {
    final formKey = GlobalKey<FormState>();
    String title = existingExpense?.title ?? '';
    double? amount = existingExpense?.amount;
    DateTime selectedDate = existingExpense?.date ?? DateTime.now();
    // Ensure the selectedCategory from existingExpense is one of the predefined ones for Dropdown initial value
    Category selectedCategory = Category.predefinedCategories.firstWhere(
      (cat) => cat.name == existingExpense?.category.name,
      orElse: () => Category.predefinedCategories.first,
    );

    bool isEditing = existingExpense != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
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
                          isEditing ? 'Edit Expense' : 'Add New Expense',
                          style: Theme.of(
                            context,
                          ).textTheme.displayLarge?.copyWith(
                            fontSize: 22,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextFormField(
                        initialValue: title,
                        decoration: const InputDecoration(
                          labelText: 'Title/Description',
                          hintText: 'e.g. Coffee with friends',
                        ),
                        style: GoogleFonts.lato(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title.';
                          }
                          return null;
                        },
                        onSaved: (value) => title = value!.trim(),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue: amount?.toStringAsFixed(2),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                          hintText: '0.00',
                        ),
                        style: GoogleFonts.lato(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount.';
                          }
                          final parsedAmount = double.tryParse(value);
                          if (parsedAmount == null) {
                            return 'Please enter a valid number.';
                          }
                          if (parsedAmount <= 0) {
                            return 'Amount must be positive.';
                          }
                          return null;
                        },
                        onSaved: (value) => amount = double.parse(value!),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items:
                            Category.predefinedCategories.map((
                              Category category,
                            ) {
                              return DropdownMenuItem<Category>(
                                value:
                                    category, // Ensure this matches the type of selectedCategory
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      category.icon,
                                      color: category.color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      category.name,
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
                                value == null
                                    ? 'Please select a category'
                                    : null,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: ${DateFormat.yMMMMd().format(selectedDate)}',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(
                              Icons.edit_calendar_outlined,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            label: Text(
                              'Change Date',
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
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Add Expense',
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
                              _deleteExpense(existingExpense.id);
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

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      _buildHomeScreen(),
      _buildExpensesListScreen(),
      _buildReportsScreen(), // This will now use the state variables for filters
    ];

    final List<String> titles = <String>[
      'FinTrack Dashboard',
      'All Expenses',
      'Spending Reports',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        elevation: _selectedIndex == 0 ? 0 : 2,
        backgroundColor:
            _selectedIndex == 0
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor:
            _selectedIndex == 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).appBarTheme.foregroundColor,
        titleTextStyle:
            _selectedIndex == 0
                ? GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )
                : Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: IndexedStack(index: _selectedIndex, children: widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
      ),
      floatingActionButton:
          _selectedIndex == 0 || _selectedIndex == 1
              ? FloatingActionButton.extended(
                onPressed: () => _showAddExpenseModal(),
                icon: const Icon(Icons.add, size: 24),
                label: Text(
                  'Add New',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                elevation: 4,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.black87,
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
