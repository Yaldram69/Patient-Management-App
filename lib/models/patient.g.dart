// GENERATED CODE - manual adapter for Patient (fixed)
import 'package:hive/hive.dart';
import 'patient.dart';

class PatientAdapter extends TypeAdapter<Patient> {
  @override
  final int typeId = 0;

  @override
  Patient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    // safe parsing for age (handles int, double, string, null)
    final dynamic ageRaw = fields[2];
    double age;
    if (ageRaw is num) {
      age = ageRaw.toDouble();
    } else if (ageRaw is String) {
      age = double.tryParse(ageRaw) ?? 0.0;
    } else {
      age = 0.0;
    }

    // gender may not exist in older records -> default to empty string
    final dynamic genderRaw = fields[12];
    final String gender = (genderRaw is String) ? genderRaw : '';

    // BSF and BSR may not exist in older records -> default to empty string
    final dynamic bsfRaw = fields[23];
    final String bsf = (bsfRaw is String) ? bsfRaw : '';

    final dynamic bsrRaw = fields[24];
    final String bsr = (bsrRaw is String) ? bsrRaw : '';

    // fee may not exist in older records -> keep it nullable
    final dynamic feeRaw = fields[25];
    double? fee;
    if (feeRaw is num) {
      fee = feeRaw.toDouble();
    } else if (feeRaw is String) {
      fee = double.tryParse(feeRaw);
    } else {
      fee = null;
    }

    // NEW: MR Number may not exist in older records -> default to empty string
    final dynamic mrNumberRaw = fields[26];
    final String mrNumber = (mrNumberRaw is String) ? mrNumberRaw : '';

    // NEW: VCO may not exist in older records -> default to empty string
    final dynamic vcoRaw = fields[27];
    final String vco = (vcoRaw is String) ? vcoRaw : '';

    return Patient(
      id: fields[0] as String? ?? '',
      fullName: fields[1] as String? ?? '',
      age: age,
      phone: fields[3] as String? ?? '',
      cnic: fields[4] as String? ?? '',
      visitedAt: fields[5] as DateTime? ?? DateTime.now(),
      symptoms: fields[6] as String? ?? '',
      treatment: fields[7] as String? ?? '',
      referral: fields[8] as String? ?? '',
      labs: fields[9] as String? ?? '',
      ownerEmail: fields[10] as String? ?? '',
      address: fields[11] as String? ?? '',
      gender: gender,
      diagnosis: fields[13] as String? ?? '',
      so_do_wo: fields[14] as String? ?? '',
      no_of_visit: fields[15] as String? ?? '',
      weight: fields[16] as String? ?? '',
      BP: fields[17] as String? ?? '',
      pulse: fields[18] as String? ?? '',
      temperature: fields[19] as String? ?? '',
      RR: fields[20] as String? ?? '',
      allergies: fields[21] as String? ?? '',
      investigations: fields[22] as String? ?? '',
      BSF: bsf,
      BSR: bsr,
      fee: fee,
      mrNumber: mrNumber,
      vco: vco,
    );
  }

  @override
  void write(BinaryWriter writer, Patient obj) {
    writer.writeByte(28); // total fields (0..27)

    writer.writeByte(0);
    writer.write(obj.id);

    writer.writeByte(1);
    writer.write(obj.fullName);

    writer.writeByte(2);
    writer.write(obj.age);

    writer.writeByte(3);
    writer.write(obj.phone);

    writer.writeByte(4);
    writer.write(obj.cnic);

    writer.writeByte(5);
    writer.write(obj.visitedAt);

    writer.writeByte(6);
    writer.write(obj.symptoms);

    writer.writeByte(7);
    writer.write(obj.treatment);

    writer.writeByte(8);
    writer.write(obj.referral);

    writer.writeByte(9);
    writer.write(obj.labs);

    writer.writeByte(10);
    writer.write(obj.ownerEmail);

    writer.writeByte(11);
    writer.write(obj.address);

    writer.writeByte(12);
    writer.write(obj.gender);

    writer.writeByte(13);
    writer.write(obj.diagnosis);

    writer.writeByte(14);
    writer.write(obj.so_do_wo);

    writer.writeByte(15);
    writer.write(obj.no_of_visit);

    writer.writeByte(16);
    writer.write(obj.weight);

    writer.writeByte(17);
    writer.write(obj.BP);

    writer.writeByte(18);
    writer.write(obj.pulse);

    writer.writeByte(19);
    writer.write(obj.temperature);

    writer.writeByte(20);
    writer.write(obj.RR);

    writer.writeByte(21);
    writer.write(obj.allergies);

    writer.writeByte(22);
    writer.write(obj.investigations);

    writer.writeByte(23);
    writer.write(obj.BSF ?? '');

    writer.writeByte(24);
    writer.write(obj.BSR ?? '');

    writer.writeByte(25);
    writer.write(obj.fee);

    // NEW: MR Number
    writer.writeByte(26);
    writer.write(obj.mrNumber);

    // NEW: VCO
    writer.writeByte(27);
    writer.write(obj.vco);
  }
}