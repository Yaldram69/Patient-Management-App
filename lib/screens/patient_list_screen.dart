import 'dart:math' as math;

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;

import '../models/patient.dart';
import '../services/db.dart';
import '../services/auth.dart';
import '../services/theme_provider.dart';
import 'add_edit_patient.dart';
import 'patient_detail.dart';

import '../ui/patient_list_helpers.dart';
import '../ui/patient_list_widgets.dart';
import '../ui/app_theme.dart';

enum QuickFilter { all, today, last7, last30 }

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  late Future<Box<Patient>> _openBoxFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  DateTime? _selectedDate;
  QuickFilter _quickFilter = QuickFilter.all;

  @override
  void initState() {
    super.initState();
    _openBoxFuture = DatabaseService.openPatientBox();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  bool _isVcoChecked(String? vco) {
    final x = (vco ?? '').trim().toLowerCase();
    return x == 'true' || x == '1' || x == 'yes' || x == 'y';
  }

  String _displayMrn(Patient p) {
    final mrn = p.mrNumber.trim();
    return mrn.isEmpty ? '—' : mrn;
  }

  void _printPatient(Patient p, BuildContext context) async {
    final doc = pw.Document();

    Uint8List? signatureBytes;
    final assetCandidates = [
      'assets/images/signature.png',
      'assets/images/signature.jpeg',
      'assets/images/signature.jpg',
    ];

    for (final name in assetCandidates) {
      try {
        final data = await rootBundle.load(name);
        signatureBytes = data.buffer.asUint8List();
        debugPrint('Loaded signature from asset: $name');
        break;
      } catch (e) {
        debugPrint('Asset not found: $name');
      }
    }

    if (signatureBytes == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature image not found; printing without signature'),
        ),
      );
    }

    final visited = p.visitedAt;
    final timeStr = DateFormat.jm().format(visited.toLocal());
    final dateStr = DateFormat('dd-MM-yyyy').format(visited.toLocal());
    final vcoChecked = _isVcoChecked(p.vco);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (pw.Context ctx) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ALSHIFA CLINIC',
                          style: pw.TextStyle(
                            fontSize: 34,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'DK 61/1, Farooq E Azam Road, Rawalpindi',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'PM&DC Reg. No.19970-P',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          'PHC Reg. No. R-43552    PHC R.L. No. PL-43352',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'DR AZHAR MAHMOOD',
                                  style: pw.TextStyle(
                                    fontSize: 15,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text('MBBS', style: const pw.TextStyle(fontSize: 11)),
                                pw.Text('RMP', style: const pw.TextStyle(fontSize: 11)),
                              ],
                            ),
                            pw.SizedBox(width: 12),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Container(height: 4, color: PdfColors.red),

                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: PdfColors.grey200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Patient Name: ${p.fullName}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'MRN: ${p.mrNumber.trim().isNotEmpty ? p.mrNumber : '__________________'}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'No. of Visit: ${p.no_of_visit.isNotEmpty ? p.no_of_visit : '__________________'}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Address: ${p.address.isNotEmpty ? p.address : '__________________'}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Fee: ${p.fee != null ? p.fee!.toString() : '__________________'}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'S/o, D/o, W/o: ${p.so_do_wo.isNotEmpty ? p.so_do_wo : '__________________'}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Time : $timeStr    Date/s: $dateStr',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Contact No. ${p.phone.isNotEmpty ? p.phone : '__________________'}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'VCO: ${vcoChecked ? 'Yes' : 'No'}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 150,
                        padding: const pw.EdgeInsets.only(right: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 14),
                            pw.Text('B.P', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.BP.isNotEmpty ? p.BP : '',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('Pulse', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.pulse.isNotEmpty ? p.pulse : '',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('Temperature', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.temperature.isNotEmpty ? p.temperature : '',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('RR', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.RR.isNotEmpty ? p.RR : '',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('BSF', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              (p.BSF ?? '').isNotEmpty ? p.BSF! : '',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('BSR', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              (p.BSR ?? '').isNotEmpty ? p.BSR! : '',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('Allergies', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.allergies.isNotEmpty ? p.allergies : '',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('Presenting Complaints', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.symptoms.isNotEmpty ? p.symptoms : '',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 18),

                            pw.Text('Investigations', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.investigations.isNotEmpty ? p.investigations : '',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Spacer(),
                          ],
                        ),
                      ),

                      pw.Container(
                        width: 1,
                        color: PdfColors.grey300,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                      ),

                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 10),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    'Age: ${_formatAgeDisplay(p.age)}       '
                                    'Gender: ${p.gender.isNotEmpty ? p.gender : ''}       '
                                    'Weight (kg): ${p.weight.isNotEmpty ? p.weight : ''}',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 16),
                            pw.Text(
                              'Provisional/Diagnosis: ${p.diagnosis}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.SizedBox(height: 12),

                            pw.Expanded(
                              child: pw.Stack(
                                children: [
                                  pw.Positioned.fill(
                                    child: pw.Container(
                                      padding: const pw.EdgeInsets.all(12),
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border.all(color: PdfColors.grey200),
                                      ),
                                      child: pw.Text(
                                        '\n\n${p.treatment.isNotEmpty ? p.treatment : ''}',
                                        style: const pw.TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  pw.Positioned.fill(
                                    child: pw.Center(
                                      child: pw.Transform.rotate(
                                        angle: 0,
                                        child: pw.Opacity(
                                          opacity: 0.08,
                                          child: pw.Container(
                                            padding: const pw.EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border.all(color: PdfColors.grey300),
                                              borderRadius: pw.BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            pw.SizedBox(height: 12),

                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  'Not Valid for Courts',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red,
                                  ),
                                ),
                                pw.Spacer(),
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.SizedBox(height: 6),
                                    if (signatureBytes != null)
                                      pw.Container(
                                        height: 80,
                                        width: 400,
                                        child: pw.Image(
                                          pw.MemoryImage(signatureBytes),
                                          fit: pw.BoxFit.contain,
                                        ),
                                      ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      '(Signature & Stamp)',
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Refill   0   1   2   3   4',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Contact Number : 0307-9709900',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.red,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Clinic days & timings : 10:00AM to 01:00PM & 06:00PM to 10:00PM',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _manualRefresh() => setState(() {});

  Future<void> _pickDate(BuildContext context, Color accent) async {
    final DateTime? picked = await pickDateFromContext(
      context,
      initial: _selectedDate,
      accentColor: accent,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _quickFilter = QuickFilter.all;
      });
    }
  }

  void _clearDateFilter() => setState(() => _selectedDate = null);

  void _setQuickFilter(QuickFilter f) {
    setState(() {
      _quickFilter = f;
      _selectedDate = null;
    });
  }

  String _initials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  bool _matchesQuickFilter(Patient p, QuickFilter f) {
    if (f == QuickFilter.all) return true;

    final visitedLocal = p.visitedAt.toLocal();
    final now = DateTime.now();

    if (f == QuickFilter.today) {
      return visitedLocal.year == now.year &&
          visitedLocal.month == now.month &&
          visitedLocal.day == now.day;
    }

    if (f == QuickFilter.last7) {
      final cutoff = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      return visitedLocal.isAfter(cutoff.subtract(const Duration(seconds: 1)));
    }

    if (f == QuickFilter.last30) {
      final cutoff = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      return visitedLocal.isAfter(cutoff.subtract(const Duration(seconds: 1)));
    }

    return true;
  }

  String _formatAgeDisplay(double? age) {
    if (age == null) return '—';
    if (age <= 0) return '—';
    final totalMonths = (age * 12).round();
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? 'year' : 'years'}');
    if (months > 0) parts.add('$months ${months == 1 ? 'month' : 'months'}');

    if (parts.isEmpty) return '—';
    return parts.join(' ');
  }

  pw.Widget _sectionBox({required String title, required String content}) {
    final display = content.trim().isEmpty ? '—' : content;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(display),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final themeProv = Provider.of<ThemeProvider>(context, listen: true);
    final dateFormat = DateFormat.yMMMd();
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;

    final trailingWidth = math.min(220.0, math.max(120.0, screenWidth * 0.22));
    final avatarRadius = math.min(36.0, math.max(20.0, screenWidth * 0.03));
    final cardHorizontalPadding = math.min(36.0, math.max(12.0, screenWidth * 0.03));

    final _accentColor = themeProv.accentColor;
    final _darkMode = themeProv.isDark;
    final localTheme = AppTheme.themeData(accentColor: _accentColor, darkMode: _darkMode);

    final cardColor = _darkMode ? Colors.grey[900] : Colors.white;

    return Theme(
      data: localTheme,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        drawer: buildDrawer(
          context: context,
          auth: auth,
          initials: _initials(auth.userEmail),
        ),
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: !_isSearching
              ? const Text('Patients', style: TextStyle(color: Colors.white))
              : buildSearchField(
                  themeContext: context,
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onChanged: (q) => setState(() => _searchQuery = q),
                  onClear: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                  accentColor: _accentColor,
                ),
          centerTitle: false,
          elevation: 2,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor,
                  _accentColor.withOpacity(0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: _isSearching
              ? [
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    tooltip: 'Close search',
                    onPressed: _stopSearch,
                  ),
                ]
              : [
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: _startSearch,
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.calendar_today_outlined),
                    tooltip: 'Pick date',
                    onPressed: () => _pickDate(context, _accentColor),
                  ),
                  const SizedBox(width: 6),
                ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _quickFilter == QuickFilter.all,
                                selectedColor: _accentColor.withOpacity(0.18),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                onSelected: (_) => _setQuickFilter(QuickFilter.all),
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: const Text('Today'),
                                selected: _quickFilter == QuickFilter.today,
                                selectedColor: _accentColor.withOpacity(0.18),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                onSelected: (_) => _setQuickFilter(QuickFilter.today),
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: const Text('Last 7 days'),
                                selected: _quickFilter == QuickFilter.last7,
                                selectedColor: _accentColor.withOpacity(0.18),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                onSelected: (_) => _setQuickFilter(QuickFilter.last7),
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: const Text('Last 30 days'),
                                selected: _quickFilter == QuickFilter.last30,
                                selectedColor: _accentColor.withOpacity(0.18),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                onSelected: (_) => _setQuickFilter(QuickFilter.last30),
                              ),
                              const SizedBox(width: 12),
                              if (_selectedDate != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                  label: Text(
                                    dateFormat.format(_selectedDate!),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: _accentColor,
                                ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: FutureBuilder<Box<Patient>>(
          future: _openBoxFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to open data store: ${snapshot.error}'),
              );
            }

            final box = snapshot.data!;

            return SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ValueListenableBuilder<Box<Patient>>(
                      valueListenable: box.listenable(),
                      builder: (context, Box<Patient> box, _) {
                        final current = auth.userEmail ?? '';
                        final List<Patient> filtered = box.values.where((p) {
                          final owner = p.ownerEmail;
                          if (owner != current) return false;

                          if (_selectedDate != null) {
                            if (!matchesExactDate(p, _selectedDate)) return false;
                          } else {
                            if (!_matchesQuickFilter(p, _quickFilter)) return false;
                          }

                          if (!matchesQuery(p, _searchQuery)) return false;
                          return true;
                        }).toList();

                        final total = filtered.length;

                        return Row(
                          children: [
                            Text(
                              '$total patients',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _selectedDate = null;
                                  _quickFilter = QuickFilter.all;
                                });
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear filters'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  Expanded(
                    child: ValueListenableBuilder<Box<Patient>>(
                      valueListenable: box.listenable(),
                      builder: (context, Box<Patient> box, _) {
                        final current = auth.userEmail ?? '';

                        final List<MapEntry<dynamic, Patient>> entries = box.toMap().entries.where((e) {
                          final val = e.value;
                          final owner = val.ownerEmail;
                          if (owner != current) return false;

                          if (_selectedDate != null) {
                            if (!matchesExactDate(val, _selectedDate)) return false;
                          } else {
                            if (!_matchesQuickFilter(val, _quickFilter)) return false;
                          }

                          if (!matchesQuery(val, _searchQuery)) return false;
                          return true;
                        }).toList();

                        entries.sort((a, b) => b.value.visitedAt.compareTo(a.value.visitedAt));

                        if (entries.isEmpty) {
                          return buildEmptyState(
                            context,
                            accentColor: _accentColor,
                            onAddPatient: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditPatientScreen(),
                                ),
                              );
                              setState(() {});
                            },
                          );
                        }

                        final bottomPadding = mq.padding.bottom + 96.0;

                        return ListView.separated(
                          padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final e = entries[index];
                            final patientKey = e.key as int;
                            final patient = e.value;

                            final genderShort = patient.gender.isNotEmpty ? patient.gender : null;
                            final ageDisplay = _formatAgeDisplay(patient.age);
                            final genderAgeText = (genderShort != null && genderShort.isNotEmpty)
                                ? '$genderShort • $ageDisplay'
                                : 'Age: $ageDisplay';

                            final mrnText = _displayMrn(patient);
                            final vcoChecked = _isVcoChecked(patient.vco);

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: cardHorizontalPadding),
                              child: Card(
                                color: cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PatientDetailScreen(patientKey: patientKey),
                                    ),
                                  ),
                                  onLongPress: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Patient'),
                                        content: Text('Delete ${patient.fullName}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await box.delete(patientKey);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Patient deleted')),
                                        );
                                      }
                                      setState(() {});
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final trailingW = math.min(
                                          trailingWidth,
                                          constraints.maxWidth * 0.28,
                                        );

                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: avatarRadius,
                                              backgroundColor: _accentColor.withOpacity(0.12),
                                              child: Text(
                                                _initials(patient.fullName),
                                                style: TextStyle(
                                                  color: _accentColor,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    patient.fullName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),

                                                  // NEW: MRN + VCO row
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 6,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _accentColor.withOpacity(0.08),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          'MRN: $mrnText',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: _accentColor,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: vcoChecked
                                                              ? Colors.green.withOpacity(0.10)
                                                              : Colors.grey.withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          vcoChecked ? 'VCO ✓' : 'VCO ☐',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: vcoChecked ? Colors.green[700] : Colors.grey[700],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          genderAgeText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      if (patient.phone.isNotEmpty)
                                                        Flexible(
                                                          child: Text(
                                                            '• ${patient.phone}',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (patient.address.isNotEmpty)
                                                    Text(
                                                      patient.address,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: theme.textTheme.bodySmall?.color,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    patient.symptoms.trim().isEmpty ? '—' : patient.symptoms.trim(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: theme.textTheme.bodySmall?.color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: trailingW),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Align(
                                                    alignment: Alignment.topRight,
                                                    child: PopupMenuButton<String>(
                                                      padding: EdgeInsets.zero,
                                                      icon: const Icon(Icons.more_vert, size: 20),
                                                      color: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      elevation: 6,
                                                      onSelected: (choice) async {
                                                        if (choice == 'edit') {
                                                          await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) => AddEditPatientScreen(
                                                                patientKey: patientKey,
                                                              ),
                                                            ),
                                                          );
                                                          setState(() {});
                                                        } else if (choice == 'print') {
                                                          _printPatient(patient, context);
                                                        } else if (choice == 'delete') {
                                                          final confirm = await showDialog<bool>(
                                                            context: context,
                                                            builder: (ctx) => AlertDialog(
                                                              title: const Text('Delete Patient'),
                                                              content: Text(
                                                                'Are you sure you want to delete ${patient.fullName}?',
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(ctx, false),
                                                                  child: const Text('Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () => Navigator.pop(ctx, true),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: Colors.redAccent,
                                                                  ),
                                                                  child: const Text(
                                                                    'Delete',
                                                                    style: TextStyle(color: Colors.white),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (confirm == true) {
                                                            await box.delete(patientKey);
                                                            if (mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text('Patient deleted'),
                                                                ),
                                                              );
                                                            }
                                                            setState(() {});
                                                          }
                                                        }
                                                      },
                                                      itemBuilder: (ctx) => [
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.edit,
                                                                size: 18,
                                                                color: Colors.blueAccent,
                                                              ),
                                                              SizedBox(width: 10),
                                                              Text(
                                                                'Edit',
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'print',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.print,
                                                                size: 18,
                                                                color: Colors.green,
                                                              ),
                                                              SizedBox(width: 10),
                                                              Text(
                                                                'Print',
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.delete,
                                                                size: 18,
                                                                color: Colors.redAccent,
                                                              ),
                                                              SizedBox(width: 10),
                                                              Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.redAccent,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _accentColor.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      DateFormat.MMMd().format(patient.visitedAt.toLocal()),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _accentColor,
                                                      ),
                                                      textAlign: TextAlign.right,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add patient',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditPatientScreen(),
              ),
            );
            setState(() {});
          },
        ),
      ),
    );
  }
}