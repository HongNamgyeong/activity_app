enum TimePickerStyle {
  dial,
  wheel;

  String get storageValue => name;

  static TimePickerStyle fromStorage(String? value) {
    if (value == TimePickerStyle.wheel.storageValue) {
      return TimePickerStyle.wheel;
    }
    return TimePickerStyle.dial;
  }
}
