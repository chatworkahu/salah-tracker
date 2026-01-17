import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PrayerChallengeApp());
}

class PrayerChallengeApp extends StatelessWidget {
  const PrayerChallengeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تحدي الصلاة - 40 يوم',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const PrayerChallengeHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PrayerChallengeHome extends StatefulWidget {
  const PrayerChallengeHome({Key? key}) : super(key: key);

  @override
  State<PrayerChallengeHome> createState() => _PrayerChallengeHomeState();
}

class _PrayerChallengeHomeState extends State<PrayerChallengeHome> {
  Map<int, Map<String, bool>> prayerData = {};
  int currentDay = 1;
  DateTime? startDate;
  
  final List<String> prayers = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentDay = prefs.getInt('currentDay') ?? 1;
      final dataString = prefs.getString('prayerData');
      if (dataString != null) {
        final decoded = json.decode(dataString) as Map<String, dynamic>;
        prayerData = decoded.map((key, value) => MapEntry(
          int.parse(key),
          Map<String, bool>.from(value as Map),
        ));
      } else {
        _initializePrayerData();
      }
      
      final startDateString = prefs.getString('startDate');
      if (startDateString != null) {
        startDate = DateTime.parse(startDateString);
      }
    });
  }

  void _initializePrayerData() {
    for (int i = 1; i <= 40; i++) {
      prayerData[i] = {
        for (var prayer in prayers) prayer: false,
      };
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentDay', currentDay);
    final dataToSave = prayerData.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('prayerData', json.encode(dataToSave));
    if (startDate != null) {
      await prefs.setString('startDate', startDate!.toIso8601String());
    }
  }

  void _togglePrayer(int day, String prayer) {
    setState(() {
      prayerData[day]![prayer] = !prayerData[day]![prayer]!;
      _updateCurrentDay();
    });
    _saveData();
  }

  void _updateCurrentDay() {
    for (int i = 1; i <= 40; i++) {
      bool allPrayersCompleted = prayerData[i]!.values.every((completed) => completed);
      if (!allPrayersCompleted) {
        currentDay = i;
        return;
      }
    }
    currentDay = 40;
  }

  void _resetChallenge() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين التحدي', textAlign: TextAlign.right),
        content: const Text(
          'هل أنت متأكد من إعادة تعيين التحدي؟\nسيتم حذف جميع البيانات والبدء من جديد.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initializePrayerData();
                currentDay = 1;
                startDate = DateTime.now();
              });
              _saveData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('إعادة تعيين', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  double _getProgress() {
    int totalPrayers = 40 * 5;
    int completedPrayers = 0;
    
    prayerData.forEach((day, prayers) {
      completedPrayers += prayers.values.where((completed) => completed).length;
    });
    
    return completedPrayers / totalPrayers;
  }

  int _getCompletedDays() {
    int completed = 0;
    for (int i = 1; i <= 40; i++) {
      if (prayerData[i]!.values.every((val) => val)) {
        completed++;
      }
    }
    return completed;
  }

  @override
  Widget build(BuildContext context) {
    if (prayerData.isEmpty) {
      _initializePrayerData();
    }
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade700,
                Colors.teal.shade600,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressSection(),
                Expanded(
                  child: _buildDaysList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _resetChallenge,
          backgroundColor: Colors.red.shade700,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('إعادة التحدي', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.mosque, size: 60, color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            'تحدي الصلاة في المسجد',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '40 يوماً مع التكبيرة الأولى',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '«مَنْ صَلَّى للهِ أَرْبَعِينَ يَوْمًا فِي جَمَاعَةٍ، يُدْرِكُ التَّكْبِيرَةَ الأُولَى، كُتِبَ لَهُ بَرَاءَتَانِ: بَرَاءَةٌ مِنَ النَّارِ، وَبَرَاءَةٌ مِنَ النِّفَاقِ»',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    double progress = _getProgress();
    int completedDays = _getCompletedDays();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اليوم الحالي: $currentDay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              Text(
                'مكتمل: $completedDays/40',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% مكتمل',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: 40,
        itemBuilder: (context, index) {
          int day = index + 1;
          return _buildDayCard(day);
        },
      ),
    );
  }

  Widget _buildDayCard(int day) {
    bool isCurrentDay = day == currentDay;
    bool allCompleted = prayerData[day]!.values.every((completed) => completed);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: allCompleted
            ? LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              )
            : isCurrentDay
                ? LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  )
                : null,
        color: allCompleted || isCurrentDay ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrentDay ? Colors.blue.shade700 : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: allCompleted
                      ? Colors.white
                      : isCurrentDay
                          ? Colors.white
                          : Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: allCompleted
                      ? Icon(Icons.check, color: Colors.green.shade700)
                      : Text(
                          '$day',
                          style: TextStyle(
                            color: isCurrentDay ? Colors.blue.shade700 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                'اليوم $day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: allCompleted || isCurrentDay ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${prayerData[day]!.values.where((v) => v).length}/5',
                style: TextStyle(
                  fontSize: 16,
                  color: allCompleted || isCurrentDay ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: prayers.map((prayer) {
                  bool isCompleted = prayerData[day]![prayer]!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        prayer,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      value: isCompleted,
                      onChanged: (value) => _togglePrayer(day, prayer),
                      activeColor: Colors.green.shade600,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
