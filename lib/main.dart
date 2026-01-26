import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const TungCalculatorApp());
}

// 1. Data Model
class CalculationRecord {
  final double c;
  final double r;
  final double x;
  final int n;
  final double lTotal;
  final String processLog;
  final DateTime timestamp;

  CalculationRecord({
    required this.c,
    required this.r,
    required this.x,
    required this.n,
    required this.lTotal,
    required this.processLog,
    required this.timestamp,
  });
}

class TungCalculatorApp extends StatelessWidget {
  const TungCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'คำนวณตุงใยแมงมุม',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Sarabun', 
      ),
      home: const CalculatorHome(),
    );
  }
}

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final TextEditingController _cController = TextEditingController(); 
  final TextEditingController _rController = TextEditingController(); 
  final TextEditingController _xController = TextEditingController(); 

  // State
  final List<CalculationRecord> _history = [];
  CalculationRecord? _currentResult;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cController.dispose();
    _rController.dispose();
    _xController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _errorMessage = '';
      _currentResult = null;
    });

    try {
      // --- 1. Parsing Inputs ---
      final double cVal = double.parse(_cController.text);
      final double rVal = double.parse(_rController.text);
      final double xVal = double.parse(_xController.text);
      
      // Constraint: s = x
      final double sVal = xVal; 

      if (xVal <= 0) {
        setState(() => _errorMessage = "ค่า x (ความหนาไหมพรม) ต้องมากกว่า 0");
        return;
      }
       if (rVal * 2 >= cVal) {
        setState(() => _errorMessage = "ค่า C ต้องมากกว่า 2r (โครงต้องยาวกว่าแกนกลาง)");
        return;
      }

      // --- 2. Logging Setup (Thai) ---
      StringBuffer log = StringBuffer();
      log.writeln("--- ข้อมูลนำเข้า (Inputs) ---");
      log.writeln("C (ความยาวไม้โครง) = $cVal cm");
      log.writeln("r (รัศมีแกนกลาง)    = $rVal cm");
      log.writeln("x (ความหนาไหมพรม) = $xVal cm");
      log.writeln("s (ระยะห่าง = x)    = $sVal cm");
      log.writeln("");

      // --- 3. Calculate n (จำนวนชั้น) ---
      log.writeln("--- ขั้นตอนที่ 1: หาจำนวนชั้น (n) ---");
      // Formula: n = floor( [ (C-2r)/2 - s ] / x )
      
      double halfLength = (cVal - (2 * rVal)) / 2;
      log.writeln("1. หาความยาวด้านเดียว (หักแกนกลาง):");
      log.writeln("   (C - 2r)/2 = ($cVal - ${2*rVal})/2 = $halfLength cm");
      
      double remainingSpace = halfLength - sVal;
      log.writeln("2. หักระยะเริ่มต้น (s): $halfLength - $sVal = $remainingSpace");
      
      double division = remainingSpace / xVal;
      log.writeln("3. หารด้วยความหนาไหมพรม (x):");
      log.writeln("   $remainingSpace / $xVal = ${division.toStringAsFixed(4)}");
      
      int n = division.floor();
      if (n < 0) n = 0; // Safety
      log.writeln("4. ปัดเศษลงเป็นจำนวนเต็ม:");
      log.writeln("   n = $n ชั้น");
      log.writeln("");

      // --- 4. Calculate Summation (L) ---
      log.writeln("--- ขั้นตอนที่ 2: คำนวณความยาวไหมพรม ---");
      double summation = 0;

      for (int i = 1; i <= n; i++) {
        // Term A: 3√2 * (s + (i-1)x)
        double termAInner = sVal + (i - 1) * xVal;
        double termA = 3 * sqrt(2) * termAInner;

        // Term B: sqrt( (s + (i-1)x)^2 + (s + ix)^2 )
        double part1Inner = sVal + (i - 1) * xVal;
        double part2Inner = sVal + i * xVal;
        
        double part1Sq = pow(part1Inner, 2).toDouble();
        double part2Sq = pow(part2Inner, 2).toDouble();
        double termB = sqrt(part1Sq + part2Sq);

        double iterationTotal = termA + termB;
        summation += iterationTotal;

        // Log detailed steps for first 3 and last iteration only
        if (i <= 3 || i == n) {
          log.writeln("ชั้นที่ $i:");
          log.writeln("   ความยาวส่วนโครง = ${termA.toStringAsFixed(3)}");
          log.writeln("   ความยาวส่วนทแยง = ${termB.toStringAsFixed(3)}");
          log.writeln("   รวมชั้นนี้ = ${iterationTotal.toStringAsFixed(3)}");
        } else if (i == 4 && n > 5) {
          log.writeln("... (ละการแสดงผลชั้นกลางๆ เพื่อความกระชับ) ...");
        }
      }
      log.writeln("ผลรวมความยาวทุกชั้น = ${summation.toStringAsFixed(4)} cm");
      log.writeln("");

      // --- 5. Calculate Constant Part ---
      log.writeln("--- ขั้นตอนที่ 3: ส่วนประกอบเพิ่มเติม ---");
      // Formula: (4n + 1) * [ 2 * pi * (r + x/2) ]
      double multiplier = (4.0 * n) + 1.0;
      double radiusTerm = rVal + (xVal / 2);
      double bracketContent = 2 * pi * radiusTerm;
      double constantPart = multiplier * bracketContent;

      log.writeln("ตัวคูณ (4n+1) = $multiplier");
      log.writeln("เส้นรอบวง (2π(r + x/2)) = ${bracketContent.toStringAsFixed(4)}");
      log.writeln("ค่าคงที่รวม = ${constantPart.toStringAsFixed(4)} cm");
      log.writeln("");

      // --- 6. Final Result ---
      double lTotal = summation + constantPart;
      log.writeln("--- สรุปผลการคำนวณ ---");
      log.writeln("L = ผลรวมทุกชั้น + ค่าคงที่");
      log.writeln("L = $summation + $constantPart");
      log.writeln("L = $lTotal cm");

      final record = CalculationRecord(
        c: cVal, r: rVal, x: xVal,
        n: n,
        lTotal: lTotal,
        processLog: log.toString(),
        timestamp: DateTime.now(),
      );

      setState(() {
        _currentResult = record;
        _history.insert(0, record); // Add to top of history
      });
      
      // Hide keyboard after successful calculation
      FocusScope.of(context).unfocus();

    } catch (e) {
      setState(() {
        _errorMessage = "ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบตัวเลข";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คำนวณตุงใยแมงมุม', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.calculate), text: 'เครื่องคำนวณ'),
            Tab(icon: Icon(Icons.history), text: 'ประวัติ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // --- TAB 1: CALCULATOR ---
  Widget _buildCalculatorTab() {
    // Get the current number of layers, or 0 if no calculation done yet.
    final int layersToShow = _currentResult?.n ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- VISUALIZATION AREA ---
          TungVisualization(layers: layersToShow),
          const SizedBox(height: 20),

          // --- INPUT CARD ---
          Card(
            elevation: 4,
            // UPDATED: Fixed deprecation
            shadowColor: Colors.indigo.withValues(alpha: 0.3),
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                   children: [
                     Icon(Icons.tune, color: Colors.indigo[700]),
                     const SizedBox(width: 10),
                     const Text("กรอกข้อมูล (หน่วย cm)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                   ],
                  ),
                  const Divider(height: 25),
                  _buildTextField("C : ความยาวไม้โครงทั้งหมด", _cController),
                  const SizedBox(height: 15),
                  _buildTextField("r : รัศมีของไม้โครง (แกนกลาง)", _rController),
                  const SizedBox(height: 15),
                  _buildTextField("x : ความหนาของเส้นไหมพรม", _xController),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          
          // --- CALCULATE BUTTON ---
          ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.layers, size: 28), 
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              elevation: 5,
              shadowColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            label: const Text('คำนวณความยาวด้าย'),
          ),
          const SizedBox(height: 25),
          
          // --- ERROR MESSAGE ---
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300, width: 2)
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
            ),
          
          // --- RESULT DISPLAY ---
          if (_currentResult != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              // UPDATED: Fixed 'Colors.indigoDark' error
              child: Align(alignment: Alignment.centerLeft, child: Text("ผลลัพธ์ล่าสุด:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo))),
            ),
            _buildResultSummaryCard(_currentResult!, true),
             const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  // --- TAB 2: HISTORY ---
  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text("ยังไม่มีประวัติการคำนวณ", style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("ลองคำนวณดูสักครั้ง!", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildResultSummaryCard(item, false),
        );
      },
    );
  }

  // --- WIDGET HELPER: TEXT FIELD ---
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
        prefixIcon: const Icon(Icons.edit, color: Colors.indigoAccent, size: 20),
      ),
    );
  }

  // --- WIDGET HELPER: RESULT CARD ---
  Widget _buildResultSummaryCard(CalculationRecord record, bool isHighlight) {
    return Card(
      elevation: isHighlight ? 8 : 2,
      // UPDATED: Fixed deprecation
      shadowColor: isHighlight ? Colors.indigoAccent.withValues(alpha: 0.4) : Colors.black12,
      color: isHighlight ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isHighlight ? const BorderSide(color: Colors.indigoAccent, width: 1.5) : BorderSide.none),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isHighlight ? Colors.blue[50] : Colors.white,
        collapsedBackgroundColor: isHighlight ? Colors.white : Colors.grey[50],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                     Icon(Icons.layers, size: 20, color: Colors.grey[700]),
                     const SizedBox(width: 8),
                     Text("จำนวนชั้น (n) = ${record.n}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   ],
                 ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 24, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text("L = ${record.lTotal.toStringAsFixed(2)} cm", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.indigo)
                    ),
                  ],
                ),
              ],
            ),
             if (!isHighlight)
               Text(
                "${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2,'0')}",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8)
            ),
            child: Text(
              "ข้อมูล: C=${record.c}, r=${record.r}, x=${record.x}",
              style: TextStyle(color: Colors.grey[700], fontSize: 13, fontFamily: 'Courier'),
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          // UPDATED: Fixed deprecation
          decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.keyboard_arrow_down, color: Colors.indigo)
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              border: Border(top: BorderSide(color: Colors.grey.shade200))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description, size: 18, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text("ขั้นตอนการคำนวณละเอียด", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: SelectableText(
                    record.processLog,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 13, height: 1.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// --- VISUALIZATION WIDGETS ---
// ==========================================

class TungVisualization extends StatelessWidget {
  final int layers;

  const TungVisualization({super.key, required this.layers});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, 
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // UPDATED: Fixed deprecation
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: TungPainter(layers: layers),
          child: const Center(),
        ),
      ),
    );
  }
}

class TungPainter extends CustomPainter {
  final int layers;
  
  // Traditional Tung colors palette
  final List<Color> yarnColors = [
    const Color(0xFFE53935), // Red
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF43A047), // Green
    const Color(0xFF1E88E5), // Blue
    const Color(0xFFFB8C00), // Orange
  ];
  
  final Color stickColor = const Color(0xFFCFAE8D); 

  TungPainter({required this.layers});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double stickThickness = 12.0;
    
    // Determine size based on the widget
    final double maxRadius = min(size.width, size.height) * 0.45; 
    final double stickLength = maxRadius * 2.2;

    // --- 1. Draw Sticks ---
    final stickPaint = Paint()
      ..color = stickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stickThickness
      ..strokeCap = StrokeCap.round;

    // Horizontal Stick
    canvas.drawLine(
      Offset(center.dx - stickLength / 2, center.dy),
      Offset(center.dx + stickLength / 2, center.dy),
      stickPaint,
    );
    // Vertical Stick
    canvas.drawLine(
      Offset(center.dx, center.dy - stickLength / 2),
      Offset(center.dx, center.dy + stickLength / 2),
      stickPaint,
    );

    // --- 2. Draw Yarn (Layers) ---
    if (layers <= 0) return;

    // Calculate Spacing FIRST
    double startRadius = stickThickness * 0.8; 
    double layerSpacing = (maxRadius - startRadius) / layers;

    // KEY FIX: Set thickness to 85% of the spacing
    // This forces a 15% empty gap between every single line
    double yarnThickness = layerSpacing * 0.85;
    
    // Safety clamp: Don't let it get thinner than 1 pixel or thicker than 8 pixels
    yarnThickness = yarnThickness.clamp(1.0, 8.0);

    final yarnPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = yarnThickness 
      ..strokeJoin = StrokeJoin.round;
      
    // Change color every 2 layers
    int colorChangeFrequency = 2; 

    for (int i = 1; i <= layers; i++) {
      double currentRadius = startRadius + (i * layerSpacing);

      // Cycle through the colors
      int colorIndex = (i ~/ colorChangeFrequency) % yarnColors.length;
      yarnPaint.color = yarnColors[colorIndex];

      Path layerPath = Path();
      layerPath.moveTo(center.dx, center.dy - currentRadius); // Top
      layerPath.lineTo(center.dx + currentRadius, center.dy); // Right
      layerPath.lineTo(center.dx, center.dy + currentRadius); // Bottom
      layerPath.lineTo(center.dx - currentRadius, center.dy); // Left
      layerPath.close(); 

      canvas.drawPath(layerPath, yarnPaint);
    }
    
    // Center knot
    final centerCoverPaint = Paint()
        ..color = stickColor
        ..style = PaintingStyle.fill;
     canvas.drawCircle(center, stickThickness/2, centerCoverPaint);
  }

  @override
  bool shouldRepaint(covariant TungPainter oldDelegate) {
    return oldDelegate.layers != layers;
  }
}