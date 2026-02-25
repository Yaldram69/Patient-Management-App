// lib/ui/patient_list_widgets.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth.dart';
import '../services/theme_provider.dart';

/// Search field widget builder (keeps same API as your original).
Widget buildSearchField({
  required BuildContext themeContext,
  required TextEditingController controller,
  required String searchQuery,
  required void Function(String) onChanged,
  required VoidCallback onClear,
  required Color accentColor,
}) {
  return Container(
    height: 44,
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(themeContext).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(Icons.search, size: 22, color: accentColor),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                // UPDATED: include MRN in hint
                hintText: 'Search by name, phone, CNIC or MRN',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              ),
              onChanged: onChanged,
            ),
          ),
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClear,
            ),
        ],
      ),
    ),
  );
}

/// Empty state builder (keeps same signature — caller expects Future<void> Function()).
Widget buildEmptyState(
    BuildContext context, {
      required Color accentColor,
      required Future<void> Function() onAddPatient,
    }) {
  final theme = Theme.of(context);
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: accentColor.withOpacity(0.14)),
          const SizedBox(height: 20),
          Text('No patients found', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'No patients match your current filters. Use search (including MRN), quick filters, or add a new patient.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add patient',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              await onAddPatient();
            },
          ),
        ],
      ),
    ),
  );
}

/// Shows bottom sheet for accent selection. Calls onAccentSelected when user picks a color.
/// It does NOT directly mutate state — caller should setState after receiving the color.
Future<void> showThemeChooser({
  required BuildContext context,
  required Color currentAccent,
  required void Function(Color) onAccentSelected,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      Color sel = currentAccent;

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          void choose(Color c) {
            setLocal(() => sel = c);
            onAccentSelected(c);
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Accent',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Accent color:'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _colorChoice(Colors.blue, sel, choose),
                    _colorChoice(Colors.teal, sel, choose),
                    _colorChoice(Colors.deepPurple, sel, choose),
                    _colorChoice(Colors.orange, sel, choose),
                    _colorChoice(Colors.pink, sel, choose),
                    _colorChoice(Colors.green, sel, choose),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: sel),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _colorChoice(Color c, Color selected, void Function(Color) onTap) {
  return GestureDetector(
    onTap: () => onTap(c),
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected == c ? Colors.black26 : Colors.transparent,
          width: 2,
        ),
      ),
    ),
  );
}

/// Drawer builder — uses ThemeProvider from Provider to persist & apply theme app-wide.
Widget buildDrawer({
  required BuildContext context,
  required AuthService auth,
  required String initials,
}) {
  final themeProv = Provider.of<ThemeProvider>(context, listen: true);
  final accentColor = themeProv.accentColor;
  final darkMode = themeProv.isDark;

  return Drawer(
    child: SafeArea(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: accentColor),
            accountName: Text(auth.userEmail ?? 'Doctor'),
            accountEmail: Text(DateFormat.yMMMMd().format(DateTime.now())),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Appearance'),
            subtitle: Text(darkMode ? 'Dark mode' : 'Light mode'),
            onTap: () {
              themeProv.toggleDark();
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Accent color'),
            subtitle: const Text('Tap to change'),
            onTap: () {
              showThemeChooser(
                context: context,
                currentAccent: accentColor,
                onAccentSelected: (c) {
                  themeProv.setAccent(c);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await auth.logout();
              } catch (_) {
                try {
                  auth.logout();
                } catch (_) {}
              }
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Text(
              'Patient Manager',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );
}