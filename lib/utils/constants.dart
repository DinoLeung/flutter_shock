import 'package:flutter_blue_plus/flutter_blue_plus.dart';

final casioServiceUUID = Guid("00001804-0000-1000-8000-00805f9b34fb");
final allFeaturesCharacteristicUUID = Guid("26eb000d-b012-49a8-b1f8-394fb2032b0f");
final readCharacteristicUUID = Guid("26eb002c-b012-49a8-b1f8-394fb2032b0f");
final writeCharacteristicUUID = Guid("26eb002d-b012-49a8-b1f8-394fb2032b0f");

enum Characteristics {
  casioWatchName(0x23),
  casioAppInformation(0x22),
  casioBleFeatures(0x10),
  casioSettingForBle(0x11),
  casioWatchCondition(0x28),
  casioDstWatchState(0x1d),
  casioDstSetting(0x1e),
  casioCurrentTime(0x09),
  casioSettingForAlm(0x15),
  casioSettingForAlm2(0x16),
  casioSettingForBasic(0x13),
  casioCurrentTimeManager(0x39),
  casioWorldCities(0x1f),
  casioReminderTitle(0x30),
  casioReminderTime(0x31),
  casioTimer(0x18),
  error(0xFF),

  // ECB-30
  cmdSetTimeMode(0x47),
  findPhone(0x0A);

  final int code;

  const Characteristics(this.code);
}
