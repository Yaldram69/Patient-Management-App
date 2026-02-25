import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/patient.dart';

class DatabaseService {
  static const String patientBox = 'patients_box';
  static const String doctorsBox = 'doctors_box';

  static Future<void> init() async {
    // path_provider is used for desktop to get proper app dir
    try {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    } catch (e) {
      // already initialized by main or running on web
    }
    await Hive.openBox<Patient>(patientBox);
    await Hive.openBox(doctorsBox);
  }

  static Box<Patient> getPatientBox() => Hive.box<Patient>(patientBox);

  static Future<Box<Patient>> openPatientBox() async {
    return await Hive.openBox<Patient>(patientBox);
  }
  static Box getDoctorsBox() => Hive.box(doctorsBox);
}
