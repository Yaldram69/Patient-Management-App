// patient_detail_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/db.dart';
import '../models/patient.dart';
import 'add_edit_patient.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';

class PatientDetailScreen extends StatelessWidget {
  final int patientKey;
  const PatientDetailScreen({required this.patientKey, super.key});

  @override
  Widget build(BuildContext context) {
    final p = DatabaseService.getPatientBox().get(patientKey)!;
    final isVcoChecked = _isVcoChecked(p.vco);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.fullName.isNotEmpty ? p.fullName : 'Patient'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printPatient(p, context),
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditPatientScreen(patientKey: patientKey)),
            ),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Patient'),
                  content: Text('Are you sure you want to delete ${p.fullName}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                DatabaseService.getPatientBox().delete(patientKey);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient deleted')),
                );
              }
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = mathMin(constraints.maxWidth, 1100.0);
          final isWide = constraints.maxWidth >= 900;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: SingleChildScrollView(
                  child: isWide ? _buildWide(context, p, isVcoChecked) : _buildNarrow(context, p, isVcoChecked),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWide(BuildContext context, Patient p, bool isVcoChecked) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 4,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                    child: Text(
                      _initials(p.fullName),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // NEW: MRN + VCO
                  _infoRow(
                    icon: Icons.confirmation_number,
                    label: 'MRN',
                    value: p.mrNumber.trim().isNotEmpty ? p.mrNumber : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: isVcoChecked ? Icons.check_box : Icons.check_box_outline_blank,
                    label: 'VCO',
                    value: isVcoChecked ? 'Checked' : 'Not checked',
                  ),
                  const SizedBox(height: 8),

                  _infoRow(
                    icon: Icons.people_outline,
                    label: 'S/O, D/O, W/O',
                    value: p.so_do_wo.isNotEmpty ? p.so_do_wo : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(icon: Icons.person_outline, label: 'Age', value: _formatAgeDisplay(p.age)),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.calendar_today,
                    label: 'Visited',
                    value: DateFormat.yMMMd().add_jm().format(p.visitedAt.toLocal()),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.badge,
                    label: 'CNIC',
                    value: p.cnic.isNotEmpty ? p.cnic : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: p.phone.isNotEmpty ? p.phone : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.wc,
                    label: 'Gender',
                    value: p.gender.isNotEmpty ? p.gender : '—',
                  ),
                  const SizedBox(height: 8),

                  _infoRow(
                    icon: Icons.opacity,
                    label: 'BSF',
                    value: (p.BSF ?? '').isNotEmpty ? p.BSF! : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.show_chart,
                    label: 'BSR',
                    value: (p.BSR ?? '').isNotEmpty ? p.BSR! : '—',
                  ),
                  const SizedBox(height: 8),

                  _infoRow(
                    icon: Icons.monitor_weight,
                    label: 'Weight',
                    value: p.weight.isNotEmpty ? p.weight : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.home,
                    label: 'Address',
                    value: p.address.isNotEmpty ? p.address : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.history,
                    label: 'No. visits',
                    value: p.no_of_visit.isNotEmpty ? p.no_of_visit : '—',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.monetization_on,
                    label: 'Fee',
                    value: p.fee != null ? p.fee!.toString() : '—',
                  ),
                  const SizedBox(height: 16),

                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Edit', style: TextStyle(color: Colors.white)),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddEditPatientScreen(patientKey: patientKey)),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                        onPressed: () => _printPatient(p, context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Flexible(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context, 'Symptoms'),
                        _multilineCard(p.symptoms),
                        _sectionTitle(context, 'Diagnosis'),
                        _multilineCard(p.diagnosis),
                        _sectionTitle(context, 'Treatment'),
                        _multilineCard(p.treatment),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context, 'Referral'),
                        _multilineCard(p.referral),
                        _sectionTitle(context, 'Labs'),
                        _multilineCard(p.labs),
                        _sectionTitle(context, 'Investigations'),
                        _multilineCard(p.investigations),
                        _sectionTitle(context, 'Allergies'),
                        _multilineCard(p.allergies),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _vitalTile(icon: Icons.favorite, label: 'BP', value: p.BP.isNotEmpty ? p.BP : '—'),
                      _vitalTile(icon: Icons.speed, label: 'Pulse', value: p.pulse.isNotEmpty ? p.pulse : '—'),
                      _vitalTile(icon: Icons.thermostat, label: 'Temp', value: p.temperature.isNotEmpty ? p.temperature : '—'),
                      _vitalTile(icon: Icons.air, label: 'RR', value: p.RR.isNotEmpty ? p.RR : '—'),
                      _vitalTile(icon: Icons.opacity, label: 'BSF', value: (p.BSF ?? '').isNotEmpty ? p.BSF! : '—'),
                      _vitalTile(icon: Icons.show_chart, label: 'BSR', value: (p.BSR ?? '').isNotEmpty ? p.BSR! : '—'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context, Patient p, bool isVcoChecked) {
    final genderDisplay = p.gender.isNotEmpty ? p.gender : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                  child: Text(
                    _initials(p.fullName),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$genderDisplay • ${_formatAgeDisplay(p.age)} • ${p.phone.isNotEmpty ? p.phone : '—'} • W: ${p.weight.isNotEmpty ? p.weight : '—'} • BP: ${p.BP.isNotEmpty ? p.BP : '—'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // NEW: MRN + VCO on mobile
                      if (p.mrNumber.trim().isNotEmpty) Text('MRN: ${p.mrNumber}'),
                      Text('VCO: ${isVcoChecked ? '☑' : '☐'}'),

                      const SizedBox(height: 4),
                      if (p.cnic.isNotEmpty) Text('CNIC: ${p.cnic}'),
                      const SizedBox(height: 4),
                      if (p.address.isNotEmpty) Text('Address: ${p.address}'),
                      const SizedBox(height: 6),
                      if (p.so_do_wo.isNotEmpty) Text('S/O, D/O, W/O: ${p.so_do_wo}'),
                      if (p.no_of_visit.isNotEmpty) Text('No. visits: ${p.no_of_visit}'),
                      if (p.fee != null) Text('Fee: ${p.fee}'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('BSF: ${(p.BSF ?? '').isNotEmpty ? p.BSF! : '—'}'),
                          const SizedBox(width: 12),
                          Text('BSR: ${(p.BSR ?? '').isNotEmpty ? p.BSR! : '—'}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _sectionTitle(context, 'Symptoms'),
        _multilineCard(p.symptoms),
        _sectionTitle(context, 'Diagnosis'),
        _multilineCard(p.diagnosis),
        _sectionTitle(context, 'Treatment'),
        _multilineCard(p.treatment),
        _sectionTitle(context, 'Referral'),
        _multilineCard(p.referral),
        _sectionTitle(context, 'Labs'),
        _multilineCard(p.labs),
        _sectionTitle(context, 'Investigations'),
        _multilineCard(p.investigations),
        _sectionTitle(context, 'Allergies'),
        _multilineCard(p.allergies),

        const SizedBox(height: 12),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _vitalTile(icon: Icons.favorite, label: 'BP', value: p.BP.isNotEmpty ? p.BP : '—'),
                _vitalTile(icon: Icons.speed, label: 'Pulse', value: p.pulse.isNotEmpty ? p.pulse : '—'),
                _vitalTile(icon: Icons.thermostat, label: 'Temp', value: p.temperature.isNotEmpty ? p.temperature : '—'),
                _vitalTile(icon: Icons.air, label: 'RR', value: p.RR.isNotEmpty ? p.RR : '—'),
                _vitalTile(icon: Icons.opacity, label: 'BSF', value: (p.BSF ?? '').isNotEmpty ? p.BSF! : '—'),
                _vitalTile(icon: Icons.show_chart, label: 'BSR', value: (p.BSR ?? '').isNotEmpty ? p.BSR! : '—'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isVcoChecked(String vco) {
    final x = vco.trim().toLowerCase();
    return x == 'true' || x == '1' || x == 'yes' || x == 'y';
  }

  String _initials(String name) {
    final n = name.trim();
    if (n.isEmpty) return '';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _vitalTile({required IconData icon, required String label, required String value}) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _multilineCard(String text) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text.trim().isEmpty ? '—' : text),
      ),
    );
  }

  /// Print / PDF generation with optional signature image placed above signature box.
  void _printPatient(Patient p, BuildContext context) async {
    final doc = pw.Document();

    // --- load signature bytes (try asset names first) ---
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
      } catch (_) {
        debugPrint('Asset not found: $name');
      }
    }

    if (signatureBytes == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature image not found; proceeding without it')),
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
                // Header
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ALSHIFA CLINIC',
                          style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('DK 61/1, Farooq E Azam Road, Rawalpindi', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('PM&DC Reg. No.19970-P', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('PHC Reg. No. R-43552    PHC R.L. No. PL-43352', style: const pw.TextStyle(fontSize: 12)),
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
                                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
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

                // Patient strip
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: PdfColors.grey200,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Patient Name: ${p.fullName}', style: const pw.TextStyle(fontSize: 10)),
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
                            pw.Text('Time : $timeStr    Date/s: $dateStr', style: const pw.TextStyle(fontSize: 10)),
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
                ),

                pw.SizedBox(height: 12),

                // Main body
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left column (UPDATED ORDER + Labs/Referals added)
                      pw.Container(
                        width: 150,
                        padding: const pw.EdgeInsets.only(right: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 14),

                            // 1) Presenting Complaints
                            pw.Text('Presenting Complaints', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.symptoms.isNotEmpty ? p.symptoms : '',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 18),

                            // 2) BP
                            pw.Text('B.P', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(p.BP.isNotEmpty ? p.BP : '', style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 18),

                            // 3) Temperature
                            pw.Text('Temperature', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.temperature.isNotEmpty ? p.temperature : '',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 18),

                            // 4) Allergies
                            pw.Text('Allergies', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.allergies.isNotEmpty ? p.allergies : '',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 18),

                            // 5) Investigations
                            pw.Text('Investigations', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.investigations.isNotEmpty ? p.investigations : '',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 18),

                            // 6) Labs
                            pw.Text('Labs', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.labs.isNotEmpty ? p.labs : '',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 18),

                            // 7) Referals (as requested spelling)
                            pw.Text('Referals', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              p.referral.isNotEmpty ? p.referral : '',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 18),

                            // Then the rest (already there)
                            pw.Text('Pulse', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(p.pulse.isNotEmpty ? p.pulse : '', style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 18),

                            pw.Text('RR', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text(p.RR.isNotEmpty ? p.RR : '', style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 18),

                            pw.Text('BSF', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text((p.BSF ?? '').isNotEmpty ? p.BSF! : '', style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 18),

                            pw.Text('BSR', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text((p.BSR ?? '').isNotEmpty ? p.BSR! : '', style: const pw.TextStyle(fontSize: 9)),
                            pw.Spacer(),
                            pw.Spacer(),
                          ],
                        ),
                      ),

                      pw.Container(
                        width: 1,
                        color: PdfColors.grey300,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                      ),

                      // Right area
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
                                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                      pw.SizedBox(
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
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.red),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Clinic days & timings : 10:00AM to 01:00PM & 06:00PM to 10:00PM',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
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
      debugPrint('Printing failed: $e');
    }
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

  double mathMin(double a, double b) => a < b ? a : b;
}