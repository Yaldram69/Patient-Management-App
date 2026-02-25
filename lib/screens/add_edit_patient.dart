import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../services/db.dart';
import 'package:provider/provider.dart';
import '../services/auth.dart';
import '../ui/app_theme.dart';
import 'package:flutter/services.dart'; // for input formatters & keyboard handling

class AddEditPatientScreen extends StatefulWidget {
  final int? patientKey; // box key (not index). If editing, provide key.
  const AddEditPatientScreen({this.patientKey, super.key});

  @override
  _AddEditPatientScreenState createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _cnic = TextEditingController();
  final _sym = TextEditingController();
  final _diag = TextEditingController();
  final _treat = TextEditingController();
  final _ref = TextEditingController();
  final _labs = TextEditingController();
  final _address = TextEditingController();

  DateTime _visited = DateTime.now();

  // MRN + VCO
  final _mrn = TextEditingController(); // read-only display (auto generated/preserved)
  bool _vco = false; // checkbox

  // Small fields controllers
  final _soDoWo = TextEditingController();
  final _noOfVisit = TextEditingController();
  final _weight = TextEditingController();
  final _bp = TextEditingController();
  final _pulse = TextEditingController();
  final _temperature = TextEditingController();
  final _rr = TextEditingController();
  final _allergies = TextEditingController();
  final _investigations = TextEditingController();

  // BSF and BSR controllers
  final _bsf = TextEditingController();
  final _bsr = TextEditingController();

  // Fee controller
  final _fee = TextEditingController();

  // Focus nodes (keyboard-first navigation)
  late final FocusNode _fnName;
  late final FocusNode _fnVco;
  late final FocusNode _fnSoDoWo;
  late final FocusNode _fnGender;
  late final FocusNode _fnAge;
  late final FocusNode _fnPhone;
  late final FocusNode _fnCnic;
  late final FocusNode _fnAddress;
  late final FocusNode _fnFee;

  late final FocusNode _fnSym;
  late final FocusNode _fnDiag;
  late final FocusNode _fnTreat;
  late final FocusNode _fnRef;
  late final FocusNode _fnLabs;
  late final FocusNode _fnAllergies;
  late final FocusNode _fnInvestigations;
  late final FocusNode _fnNoOfVisit;
  late final FocusNode _fnWeight;
  late final FocusNode _fnBp;
  late final FocusNode _fnPulse;
  late final FocusNode _fnTemperature;
  late final FocusNode _fnRr;
  late final FocusNode _fnBsf;
  late final FocusNode _fnBsr;
  late final FocusNode _fnSaveButton;

  late Future<void> _initFuture;
  bool _saving = false;

  String _agePreview = '';
  String? _gender; // 'Male' or 'Female' or null

  @override
  void initState() {
    super.initState();

    // init focus nodes first
    _fnName = FocusNode(debugLabel: 'Name');
    _fnVco = FocusNode(debugLabel: 'VCO');
    _fnSoDoWo = FocusNode(debugLabel: 'S/O D/O W/O');
    _fnGender = FocusNode(debugLabel: 'Gender');
    _fnAge = FocusNode(debugLabel: 'Age');
    _fnPhone = FocusNode(debugLabel: 'Phone');
    _fnCnic = FocusNode(debugLabel: 'CNIC');
    _fnAddress = FocusNode(debugLabel: 'Address');
    _fnFee = FocusNode(debugLabel: 'Fee');

    _fnSym = FocusNode(debugLabel: 'Symptoms');
    _fnDiag = FocusNode(debugLabel: 'Diagnosis');
    _fnTreat = FocusNode(debugLabel: 'Treatment');
    _fnRef = FocusNode(debugLabel: 'Referral');
    _fnLabs = FocusNode(debugLabel: 'Labs');
    _fnAllergies = FocusNode(debugLabel: 'Allergies');
    _fnInvestigations = FocusNode(debugLabel: 'Investigations');
    _fnNoOfVisit = FocusNode(debugLabel: 'No. Visits');
    _fnWeight = FocusNode(debugLabel: 'Weight');
    _fnBp = FocusNode(debugLabel: 'BP');
    _fnPulse = FocusNode(debugLabel: 'Pulse');
    _fnTemperature = FocusNode(debugLabel: 'Temperature');
    _fnRr = FocusNode(debugLabel: 'RR');
    _fnBsf = FocusNode(debugLabel: 'BSF');
    _fnBsr = FocusNode(debugLabel: 'BSR');
    _fnSaveButton = FocusNode(debugLabel: 'Save');

    _age.addListener(_onAgeChanged);
    _initFuture = _openAndPopulateIfEditing();
  }

  void _onAgeChanged() {
    final text = _age.text.trim();
    final d = double.tryParse(text);
    final preview = _formatAgeDisplay(d);
    if (!mounted) return;
    setState(() {
      _agePreview = preview;
    });
  }

  Future<void> _openAndPopulateIfEditing() async {
    final box = await DatabaseService.openPatientBox();

    if (widget.patientKey != null) {
      final Patient? p = box.get(widget.patientKey);
      if (p != null && mounted) {
        setState(() {
          _name.text = p.fullName;
          _age.text = p.age.toString();
          _phone.text = p.phone;
          _cnic.text = p.cnic;
          _sym.text = p.symptoms;
          _diag.text = p.diagnosis;
          _treat.text = p.treatment;
          _ref.text = p.referral;
          _labs.text = p.labs;
          _address.text = p.address;
          _visited = p.visitedAt;
          _agePreview = _formatAgeDisplay(p.age);
          _gender = p.gender.isNotEmpty ? p.gender : null;

          _mrn.text = (p.mrNumber).trim();
          _vco = (p.vco).trim().toLowerCase() == 'true' ||
              (p.vco).trim() == '1' ||
              (p.vco).trim().toLowerCase() == 'yes';

          _soDoWo.text = p.so_do_wo;
          _noOfVisit.text = p.no_of_visit;
          _weight.text = p.weight;
          _bp.text = p.BP;
          _pulse.text = p.pulse;
          _temperature.text = p.temperature;
          _rr.text = p.RR;
          _allergies.text = p.allergies;
          _investigations.text = p.investigations;

          _bsf.text = p.BSF ?? '';
          _bsr.text = p.BSR ?? '';

          _fee.text = (p.fee != null) ? p.fee!.toString() : '';
        });
      }
    }
  }

  @override
  void dispose() {
    _age.removeListener(_onAgeChanged);

    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _cnic.dispose();
    _sym.dispose();
    _diag.dispose();
    _treat.dispose();
    _ref.dispose();
    _labs.dispose();
    _address.dispose();
    _mrn.dispose();
    _soDoWo.dispose();
    _noOfVisit.dispose();
    _weight.dispose();
    _bp.dispose();
    _pulse.dispose();
    _temperature.dispose();
    _rr.dispose();
    _allergies.dispose();
    _investigations.dispose();
    _bsf.dispose();
    _bsr.dispose();
    _fee.dispose();

    _fnName.dispose();
    _fnVco.dispose();
    _fnSoDoWo.dispose();
    _fnGender.dispose();
    _fnAge.dispose();
    _fnPhone.dispose();
    _fnCnic.dispose();
    _fnAddress.dispose();
    _fnFee.dispose();

    _fnSym.dispose();
    _fnDiag.dispose();
    _fnTreat.dispose();
    _fnRef.dispose();
    _fnLabs.dispose();
    _fnAllergies.dispose();
    _fnInvestigations.dispose();
    _fnNoOfVisit.dispose();
    _fnWeight.dispose();
    _fnBp.dispose();
    _fnPulse.dispose();
    _fnTemperature.dispose();
    _fnRr.dispose();
    _fnBsf.dispose();
    _fnBsr.dispose();
    _fnSaveButton.dispose();

    super.dispose();
  }

  void _toggleVco() {
    setState(() => _vco = !_vco);
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _visited,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_visited),
      );
      if (t != null && mounted) {
        setState(() {
          _visited = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        });
      }
    }
  }

  /// Generates a unique, auto-incremented MRN.
  /// Format returned: YYYYMMDD-000001
  Future<String> _generateUniqueMrn(Box<Patient> box) async {
    final now = DateTime.now();
    final datePart =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    int maxSeq = 0;
    final used = <String>{};

    for (final dynamic item in box.values) {
      if (item is! Patient) continue;
      final mrn = item.mrNumber.trim();
      if (mrn.isEmpty) continue;

      used.add(mrn);

      final parts = mrn.split('-');
      if (parts.length == 2 && parts[0] == datePart) {
        final seq = int.tryParse(parts[1]) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      } else if (parts.length == 3 && parts[0] == 'MRN' && parts[1] == datePart) {
        // backwards compatibility if old values exist
        final seq = int.tryParse(parts[2]) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    int nextSeq = maxSeq + 1;
    String candidate = '$datePart-${nextSeq.toString().padLeft(6, '0')}';

    while (used.contains(candidate)) {
      nextSeq++;
      candidate = '$datePart-${nextSeq.toString().padLeft(6, '0')}';
    }

    return candidate;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final box = await DatabaseService.openPatientBox();
      final auth = Provider.of<AuthService>(context, listen: false);
      final currentDoctor = auth.userEmail ?? '';

      final isEdit = widget.patientKey != null;
      Patient? existing;
      if (isEdit) {
        existing = box.get(widget.patientKey) as Patient?;
      }

      String finalMrn = '';
      if (existing != null) {
        final existingMrn = existing.mrNumber.trim();
        finalMrn = existingMrn.isNotEmpty ? existingMrn : await _generateUniqueMrn(box);
      } else {
        final typedMrn = _mrn.text.trim();
        finalMrn = typedMrn.isNotEmpty ? typedMrn : await _generateUniqueMrn(box);
      }

      _mrn.text = finalMrn;

      final id = (existing?.id.isNotEmpty == true) ? existing!.id : const Uuid().v4();

      final p = Patient(
        id: id,
        fullName: _name.text.trim(),
        age: double.tryParse(_age.text.trim()) ?? 0,
        phone: _phone.text.trim(),
        cnic: _cnic.text.trim(),
        visitedAt: _visited,
        symptoms: _sym.text.trim(),
        diagnosis: _diag.text.trim(),
        treatment: _treat.text.trim(),
        referral: _ref.text.trim(),
        labs: _labs.text.trim(),
        address: _address.text.trim(),
        ownerEmail: existing?.ownerEmail.isNotEmpty == true ? existing!.ownerEmail : currentDoctor,
        gender: _gender ?? '',
        so_do_wo: _soDoWo.text.trim(),
        no_of_visit: _noOfVisit.text.trim(),
        weight: _weight.text.trim(),
        BP: _bp.text.trim(),
        pulse: _pulse.text.trim(),
        temperature: _temperature.text.trim(),
        RR: _rr.text.trim(),
        allergies: _allergies.text.trim(),
        investigations: _investigations.text.trim(),
        BSF: _bsf.text.trim(),
        BSR: _bsr.text.trim(),
        fee: double.tryParse(_fee.text.trim()),
        mrNumber: finalMrn,
        vco: _vco ? 'true' : 'false',
      );

      if (existing != null) {
        existing.fullName = p.fullName;
        existing.age = p.age;
        existing.phone = p.phone;
        existing.cnic = p.cnic;
        existing.visitedAt = p.visitedAt;
        existing.symptoms = p.symptoms;
        existing.diagnosis = p.diagnosis;
        existing.treatment = p.treatment;
        existing.referral = p.referral;
        existing.labs = p.labs;
        existing.address = p.address;
        existing.gender = p.gender;
        existing.ownerEmail = p.ownerEmail;

        existing.so_do_wo = p.so_do_wo;
        existing.no_of_visit = p.no_of_visit;
        existing.weight = p.weight;
        existing.BP = p.BP;
        existing.pulse = p.pulse;
        existing.temperature = p.temperature;
        existing.RR = p.RR;
        existing.allergies = p.allergies;
        existing.investigations = p.investigations;

        existing.BSF = p.BSF;
        existing.BSR = p.BSR;
        existing.fee = p.fee;

        existing.mrNumber = finalMrn;
        existing.vco = p.vco;

        await existing.save();
      } else {
        await box.add(p);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient saved • MRN: $finalMrn')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatAgeDisplay(double? age) {
    if (age == null || age <= 0) return '—';
    final totalMonths = (age * 12).round();
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? 'year' : 'years'}');
    if (months > 0) parts.add('$months ${months == 1 ? 'month' : 'months'}');

    return parts.isEmpty ? '—' : parts.join(' ');
  }

  InputDecoration _smallDecoration({required String label, IconData? icon, String? hint}) {
    return AppTheme.inputDecoration(label: label, icon: icon).copyWith(
      isDense: true,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );
  }

  KeyEventResult _handleSaveKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (!_saving) {
          _onSave();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleVcoKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _toggleVco();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildVcoKeyboardTile(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      focusNode: _fnVco,
      onKeyEvent: _handleVcoKey,
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return InkWell(
            onTap: _toggleVco,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasFocus ? theme.colorScheme.primary : Colors.transparent,
                  width: hasFocus ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _vco,
                    onChanged: (_) => _toggleVco(),
                  ),
                  const SizedBox(width: 4),
                  const Text('VCO'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _multilineClinicalField({
    required FocusNode focusNode,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int minLines = 1,
    int maxLines = 4,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      decoration: AppTheme.inputDecoration(label: label, icon: icon),
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline, // Enter = new line (NOT next field)
      validator: validator,
    );
  }

  Widget _multilineSmallClinicalField({
    required FocusNode focusNode,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int minLines = 1,
    int maxLines = 4,
  }) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      decoration: _smallDecoration(label: label, icon: icon, hint: hint),
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline, // Enter = newline
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patientKey != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Patient' : 'Add Patient'),
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to open data store: ${snap.error}'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = mathMin(constraints.maxWidth, 1100.0);
              final isWide = constraints.maxWidth >= 900;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: isWide ? _buildWideForm(context) : _buildNarrowForm(context),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWideForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Patient info', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),

                          FocusTraversalOrder(
                            order: const NumericFocusOrder(1.0),
                            child: TextFormField(
                              focusNode: _fnName,
                              controller: _name,
                              decoration: AppTheme.inputDecoration(label: 'Full Name', icon: Icons.person),
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // MRN display + VCO (MRN skipped in tab traversal)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Focus(
                                  skipTraversal: true,
                                  canRequestFocus: false,
                                  descendantsAreFocusable: false,
                                  child: TextFormField(
                                    controller: _mrn,
                                    readOnly: true,
                                    enableInteractiveSelection: true,
                                    decoration: AppTheme.inputDecoration(
                                      label: 'MR Number (Auto)',
                                      icon: Icons.confirmation_number,
                                      hint: 'Auto-generated on first save',
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        tooltip: 'Refresh preview (new patients only)',
                                        onPressed: widget.patientKey != null
                                            ? null
                                            : () async {
                                          final box = await DatabaseService.openPatientBox();
                                          final mrn = await _generateUniqueMrn(box);
                                          if (mounted) {
                                            setState(() => _mrn.text = mrn);
                                          }
                                        },
                                        icon: const Icon(Icons.auto_awesome),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 120, maxWidth: 190),
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1.1),
                                  child: _buildVcoKeyboardTile(context),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(1.2),
                                child: SizedBox(
                                  width: 280,
                                  child: TextFormField(
                                    focusNode: _fnSoDoWo,
                                    controller: _soDoWo,
                                    decoration: _smallDecoration(label: 'S/O, D/O, W/O', icon: Icons.people_outline),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 110, maxWidth: 170),
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1.3),
                                  child: DropdownButtonFormField<String>(
                                    focusNode: _fnGender,
                                    value: _gender,
                                    isExpanded: true,
                                    decoration: AppTheme.inputDecoration(label: 'Gender', icon: Icons.wc),
                                    items: const [
                                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                                    ],
                                    onChanged: (v) => setState(() => _gender = v),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(2.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        focusNode: _fnAge,
                                        controller: _age,
                                        decoration: AppTheme.inputDecoration(
                                          label: 'Age',
                                          icon: Icons.calendar_today,
                                          hint: 'e.g. 35 or 2.5',
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                        ],
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : (double.tryParse(v.trim()) == null ? 'Enter a valid number' : null),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _agePreview.isEmpty ? '—' : _agePreview,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(3.0),
                                  child: TextFormField(
                                    focusNode: _fnPhone,
                                    controller: _phone,
                                    decoration: AppTheme.inputDecoration(label: 'Phone', icon: Icons.phone),
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          FocusTraversalOrder(
                            order: const NumericFocusOrder(4.0),
                            child: TextFormField(
                              focusNode: _fnCnic,
                              controller: _cnic,
                              decoration: AppTheme.inputDecoration(label: 'CNIC', icon: Icons.badge),
                              textInputAction: TextInputAction.next,
                            ),
                          ),

                          const SizedBox(height: 12),

                          FocusTraversalOrder(
                            order: const NumericFocusOrder(5.0),
                            child: TextFormField(
                              focusNode: _fnAddress,
                              controller: _address,
                              decoration: AppTheme.inputDecoration(label: 'Address', icon: Icons.home),
                              minLines: 1,
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              GestureDetector(
                                onTap: _pickDateTime,
                                child: Chip(
                                  avatar: const Icon(Icons.calendar_today, size: 18),
                                  label: Text(DateFormat.yMMMd().add_jm().format(_visited)),
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                tooltip: 'Edit visited date/time',
                                onPressed: _pickDateTime,
                                icon: const Icon(Icons.edit_calendar),
                              ),
                              const Spacer(),
                              if (widget.patientKey == null)
                                IconButton(
                                  tooltip: 'Reset to now',
                                  onPressed: () => setState(() => _visited = DateTime.now()),
                                  icon: const Icon(Icons.restore),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeeCard(context, traversalOrder: 5.5),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Flexible(
              flex: 5,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clinical', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),

                      // Enter must create newline in these fields; Tab moves to next field
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(6.0),
                        child: _multilineClinicalField(
                          focusNode: _fnSym,
                          controller: _sym,
                          label: 'Symptoms',
                          icon: Icons.healing,
                          minLines: 3,
                          maxLines: 6,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      FocusTraversalOrder(
                        order: const NumericFocusOrder(6.5),
                        child: _multilineClinicalField(
                          focusNode: _fnDiag,
                          controller: _diag,
                          label: 'Diagnosis',
                          icon: Icons.description,
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      FocusTraversalOrder(
                        order: const NumericFocusOrder(7.0),
                        child: _multilineClinicalField(
                          focusNode: _fnTreat,
                          controller: _treat,
                          label: 'Treatment',
                          icon: Icons.medical_services,
                          minLines: 2,
                          maxLines: 6,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      FocusTraversalOrder(
                        order: const NumericFocusOrder(8.0),
                        child: _multilineClinicalField(
                          focusNode: _fnRef,
                          controller: _ref,
                          label: 'Referral',
                          icon: Icons.people,
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      FocusTraversalOrder(
                        order: const NumericFocusOrder(9.0),
                        child: _multilineClinicalField(
                          focusNode: _fnLabs,
                          controller: _labs,
                          label: 'Labs',
                          icon: Icons.science,
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        children: [
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.1),
                            child: SizedBox(
                              width: 230,
                              child: _multilineSmallClinicalField(
                                focusNode: _fnAllergies,
                                controller: _allergies,
                                label: 'Allergies',
                                icon: Icons.warning,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.2),
                            child: SizedBox(
                              width: 230,
                              child: _multilineSmallClinicalField(
                                focusNode: _fnInvestigations,
                                controller: _investigations,
                                label: 'Investigations',
                                icon: Icons.biotech,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.3),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnNoOfVisit,
                                controller: _noOfVisit,
                                decoration: _smallDecoration(label: 'No. Visits', icon: Icons.history),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.4),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnWeight,
                                controller: _weight,
                                decoration: _smallDecoration(label: 'Weight', icon: Icons.monitor_weight, hint: 'kg'),
                                textInputAction: TextInputAction.next,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.5),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnBp,
                                controller: _bp,
                                decoration: _smallDecoration(label: 'BP', icon: Icons.favorite, hint: '120/80'),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.6),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnPulse,
                                controller: _pulse,
                                decoration: _smallDecoration(label: 'Pulse', icon: Icons.speed, hint: 'bpm'),
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.7),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnTemperature,
                                controller: _temperature,
                                decoration: _smallDecoration(label: 'Temp', icon: Icons.thermostat, hint: '°C'),
                                textInputAction: TextInputAction.next,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.8),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnRr,
                                controller: _rr,
                                decoration: _smallDecoration(label: 'RR', icon: Icons.air, hint: 'breaths/min'),
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.85),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnBsf,
                                controller: _bsf,
                                decoration: _smallDecoration(label: 'BSF', icon: Icons.opacity),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9.9),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                focusNode: _fnBsr,
                                controller: _bsr,
                                decoration: _smallDecoration(label: 'BSR', icon: Icons.show_chart),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(10.0),
                child: Focus(
                  focusNode: _fnSaveButton,
                  onKeyEvent: _handleSaveKey,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _onSave,
                      icon: _saving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.save),
                      label: Text(
                        _saving ? 'Saving...' : 'Save',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient info', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(1.0),
                  child: TextFormField(
                    focusNode: _fnName,
                    controller: _name,
                    decoration: AppTheme.inputDecoration(label: 'Full Name', icon: Icons.person),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 8),

                // MRN (skip traversal)
                Focus(
                  skipTraversal: true,
                  canRequestFocus: false,
                  descendantsAreFocusable: false,
                  child: TextFormField(
                    controller: _mrn,
                    readOnly: true,
                    enableInteractiveSelection: true,
                    decoration: AppTheme.inputDecoration(
                      label: 'MR Number (Auto)',
                      icon: Icons.confirmation_number,
                      hint: 'Auto-generated on first save',
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(1.1),
                  child: _buildVcoKeyboardTile(context),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(1.2),
                        child: TextFormField(
                          focusNode: _fnSoDoWo,
                          controller: _soDoWo,
                          decoration: _smallDecoration(label: 'S/O, D/O, W/O', icon: Icons.people_outline),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(1.3),
                        child: DropdownButtonFormField<String>(
                          focusNode: _fnGender,
                          value: _gender,
                          decoration: AppTheme.inputDecoration(label: 'Gender', icon: Icons.wc),
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              focusNode: _fnAge,
                              controller: _age,
                              decoration: AppTheme.inputDecoration(
                                label: 'Age',
                                icon: Icons.calendar_today,
                                hint: 'e.g. 35',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Required'
                                  : (double.tryParse(v.trim()) == null ? 'Enter a valid number' : null),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _agePreview.isEmpty ? '—' : _agePreview,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(3.0),
                        child: TextFormField(
                          focusNode: _fnPhone,
                          controller: _phone,
                          decoration: AppTheme.inputDecoration(label: 'Phone', icon: Icons.phone),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(4.0),
                  child: TextFormField(
                    focusNode: _fnCnic,
                    controller: _cnic,
                    decoration: AppTheme.inputDecoration(label: 'CNIC', icon: Icons.badge),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 10),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(5.0),
                  child: TextFormField(
                    focusNode: _fnAddress,
                    controller: _address,
                    decoration: AppTheme.inputDecoration(label: 'Address', icon: Icons.home),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Chip(
                        avatar: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat.yMMMd().add_jm().format(_visited)),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit visited date/time',
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.edit_calendar),
                    ),
                    if (widget.patientKey == null)
                      IconButton(
                        tooltip: 'Reset to now',
                        onPressed: () => setState(() => _visited = DateTime.now()),
                        icon: const Icon(Icons.restore),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        _buildFeeCard(context, traversalOrder: 5.5),
        const SizedBox(height: 12),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clinical', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(6.0),
                  child: _multilineClinicalField(
                    focusNode: _fnSym,
                    controller: _sym,
                    label: 'Symptoms',
                    icon: Icons.healing,
                    minLines: 1,
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 10),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(6.5),
                  child: _multilineClinicalField(
                    focusNode: _fnDiag,
                    controller: _diag,
                    label: 'Diagnosis',
                    icon: Icons.description,
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 10),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(7.0),
                  child: _multilineClinicalField(
                    focusNode: _fnTreat,
                    controller: _treat,
                    label: 'Treatment',
                    icon: Icons.medical_services,
                    minLines: 1,
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 10),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(8.0),
                  child: _multilineClinicalField(
                    focusNode: _fnRef,
                    controller: _ref,
                    label: 'Referral',
                    icon: Icons.people,
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 10),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(9.0),
                  child: _multilineClinicalField(
                    focusNode: _fnLabs,
                    controller: _labs,
                    label: 'Labs',
                    icon: Icons.science,
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.1),
                      child: SizedBox(
                        width: 200,
                        child: _multilineSmallClinicalField(
                          focusNode: _fnAllergies,
                          controller: _allergies,
                          label: 'Allergies',
                          icon: Icons.warning,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.2),
                      child: SizedBox(
                        width: 200,
                        child: _multilineSmallClinicalField(
                          focusNode: _fnInvestigations,
                          controller: _investigations,
                          label: 'Investigations',
                          icon: Icons.biotech,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.3),
                      child: SizedBox(
                        width: 110,
                        child: TextFormField(
                          focusNode: _fnNoOfVisit,
                          controller: _noOfVisit,
                          decoration: _smallDecoration(label: 'No. visits', icon: Icons.history),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.4),
                      child: SizedBox(
                        width: 110,
                        child: TextFormField(
                          focusNode: _fnWeight,
                          controller: _weight,
                          decoration: _smallDecoration(label: 'Weight', icon: Icons.monitor_weight, hint: 'kg'),
                          textInputAction: TextInputAction.next,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.5),
                      child: SizedBox(
                        width: 120,
                        child: TextFormField(
                          focusNode: _fnBp,
                          controller: _bp,
                          decoration: _smallDecoration(label: 'BP', icon: Icons.favorite, hint: '120/80'),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.6),
                      child: SizedBox(
                        width: 110,
                        child: TextFormField(
                          focusNode: _fnPulse,
                          controller: _pulse,
                          decoration: _smallDecoration(label: 'Pulse', icon: Icons.speed, hint: 'bpm'),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.7),
                      child: SizedBox(
                        width: 120,
                        child: TextFormField(
                          focusNode: _fnTemperature,
                          controller: _temperature,
                          decoration: _smallDecoration(label: 'Temp', icon: Icons.thermostat, hint: '°C'),
                          textInputAction: TextInputAction.next,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.8),
                      child: SizedBox(
                        width: 110,
                        child: TextFormField(
                          focusNode: _fnRr,
                          controller: _rr,
                          decoration: _smallDecoration(label: 'RR', icon: Icons.air, hint: 'breaths/min'),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.85),
                      child: SizedBox(
                        width: 110,
                        child: TextFormField(
                          focusNode: _fnBsf,
                          controller: _bsf,
                          decoration: _smallDecoration(label: 'BSF', icon: Icons.opacity),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(9.9),
                      child: SizedBox(
                        width: 110,
                        child: TextFormField(
                          focusNode: _fnBsr,
                          controller: _bsr,
                          decoration: _smallDecoration(label: 'BSR', icon: Icons.show_chart),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        FocusTraversalOrder(
          order: const NumericFocusOrder(10.0),
          child: Row(
            children: [
              Expanded(
                child: Focus(
                  focusNode: _fnSaveButton,
                  onKeyEvent: _handleSaveKey,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _onSave,
                      icon: _saving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.save),
                      label: Text(
                        _saving ? 'Saving...' : 'Save',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFeeCard(BuildContext context, {required double traversalOrder}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FocusTraversalOrder(
              order: NumericFocusOrder(traversalOrder),
              child: TextFormField(
                focusNode: _fnFee,
                controller: _fee,
                decoration: AppTheme.inputDecoration(
                  label: 'Fee',
                  icon: Icons.monetization_on,
                ).copyWith(
                  hintText: 'Enter fee amount',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double mathMin(double a, double b) => a < b ? a : b;
}