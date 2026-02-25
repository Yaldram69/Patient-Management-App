import 'package:hive/hive.dart';

import 'patient.g.dart';

@HiveType(typeId: 0)
class Patient extends HiveObject {
  @HiveField(0)
  String id; // uuid

  @HiveField(1)
  String fullName;

  @HiveField(2)
  double age;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String cnic;

  @HiveField(5)
  DateTime visitedAt;

  @HiveField(6)
  String symptoms;

  @HiveField(7)
  String treatment;

  @HiveField(8)
  String referral;

  @HiveField(9)
  String labs;

  // owner / doctor identifier (email)
  @HiveField(10)
  String ownerEmail;

  @HiveField(11)
  String address;

  // gender field ("Male" or "Female")
  @HiveField(12)
  String gender;

  @HiveField(13)
  String diagnosis;

  @HiveField(14)
  String so_do_wo;

  @HiveField(15)
  String no_of_visit;

  @HiveField(16)
  String weight;

  @HiveField(17)
  String BP;

  @HiveField(18)
  String pulse;

  @HiveField(19)
  String temperature;

  @HiveField(20)
  String RR;

  @HiveField(21)
  String allergies;

  @HiveField(22)
  String investigations;

  // Newly added fields
  @HiveField(23)
  String? BSF;

  @HiveField(24)
  String? BSR;

  // fee field
  @HiveField(25)
  double? fee;

  // NEW: MR Number (permanent patient identifier; should NOT change on revisits)
  @HiveField(26)
  String mrNumber;

  // NEW: VCO
  @HiveField(27)
  String vco;

  Patient({
    required this.id,
    required this.fullName,
    required this.age,
    this.phone = '',
    this.cnic = '',
    required this.visitedAt,
    required this.symptoms,
    required this.treatment,
    this.referral = '',
    this.labs = '',
    required this.ownerEmail,
    this.address = '',
    required this.gender,
    required this.diagnosis,
    this.so_do_wo = '',
    this.no_of_visit = '',
    this.weight = '',
    this.BP = '',
    this.pulse = '',
    this.temperature = '',
    this.RR = '',
    this.allergies = '',
    this.investigations = '',
    this.BSF = '',
    this.BSR = '',
    this.fee,
    required this.mrNumber,
    this.vco = '',
  });
}