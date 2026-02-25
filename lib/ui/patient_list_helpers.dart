// lib/ui/patient_list_helpers.dart
import 'package:flutter/material.dart';
import '../models/patient.dart';

/// Filtering helpers (used by the main screen)

/// Returns true if patient `p` matches query `q` (case-insensitive).
/// Supports name, phone, CNIC, MR Number, address, and S/O-D/O-W/O.
bool matchesQuery(Patient p, String q) {
  if (q.trim().isEmpty) return true;

  final lower = q.trim().toLowerCase();

  final name = p.fullName.toLowerCase();
  final phone = p.phone.toLowerCase();
  final cnic = p.cnic.toLowerCase();
  final mrn = p.mrNumber.toLowerCase(); // NEW
  final address = p.address.toLowerCase();
  final sodo = p.so_do_wo.toLowerCase();

  // If VCO is String in your current model:
  final vco = p.vco.toLowerCase();

  return name.contains(lower) ||
      phone.contains(lower) ||
      cnic.contains(lower) ||
      mrn.contains(lower) || // NEW
      address.contains(lower) ||
      sodo.contains(lower) ||
      vco.contains(lower);
}

/// Returns true if patient's visitedAt matches `selected` (date-only comparison).
bool matchesExactDate(Patient p, DateTime? selected) {
  if (selected == null) return true;

  final a = p.visitedAt.toLocal();
  return a.year == selected.year &&
      a.month == selected.month &&
      a.day == selected.day;
}

/// Accept QuickFilter values from the screen enum (we avoid direct import cycles).
enum QuickFilterLocal { all, today, last7, last30 }

/// Matches quick filter. `f` is expected to be the QuickFilter enum from the main file;
/// function treats `f` dynamically to avoid import cycles.
bool matchesQuickFilter(Patient p, dynamic f) {
  if (f == null) return true;

  final fStr = f.toString().toLowerCase();
  if (fStr.contains('all')) return true;

  final v = p.visitedAt.toLocal();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final vDate = DateTime(v.year, v.month, v.day);

  if (fStr.contains('today')) {
    return vDate.year == todayStart.year &&
        vDate.month == todayStart.month &&
        vDate.day == todayStart.day;
  } else if (fStr.contains('last7')) {
    final start = todayStart.subtract(const Duration(days: 6)); // inclusive
    return !vDate.isBefore(start) && !vDate.isAfter(todayStart);
  } else if (fStr.contains('last30')) {
    final start = todayStart.subtract(const Duration(days: 29)); // inclusive
    return !vDate.isBefore(start) && !vDate.isAfter(todayStart);
  }

  return true;
}

/// Shows the date picker and returns the picked date (or null if cancelled).
/// Accepts an optional `initial` and `accentColor` to style the picker.
Future<DateTime?> pickDateFromContext(
    BuildContext context, {
      DateTime? initial,
      required Color accentColor,
    }) {
  final now = DateTime.now();
  final init = initial ?? now;

  return showDatePicker(
    context: context,
    initialDate: init,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 5),
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: accentColor),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: accentColor),
          ),
        ),
        child: child!,
      );
    },
  );
}