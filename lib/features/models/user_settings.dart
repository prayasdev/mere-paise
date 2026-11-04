class UserSettings {
  final String currency;
  final int weekStartsOn; // 1 (Mon) .. 7 (Sun)
  final int monthStartDay; // 1 .. 28
  final bool isVellumTheme;
  final bool isBiometricEnabled;
  final int? monthlyBudgetPaise;

  const UserSettings({
    this.currency = 'INR',
    this.weekStartsOn = 1,
    this.monthStartDay = 1,
    this.isVellumTheme = false,
    this.isBiometricEnabled = false,
    this.monthlyBudgetPaise,
  });

  UserSettings copyWith({
    String? currency,
    int? weekStartsOn,
    int? monthStartDay,
    bool? isVellumTheme,
    bool? isBiometricEnabled,
    int? monthlyBudgetPaise,
    bool clearBudget = false,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      monthStartDay: monthStartDay ?? this.monthStartDay,
      isVellumTheme: isVellumTheme ?? this.isVellumTheme,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      monthlyBudgetPaise: clearBudget ? null : (monthlyBudgetPaise ?? this.monthlyBudgetPaise),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'weekStartsOn': weekStartsOn,
      'monthStartDay': monthStartDay,
      'isVellumTheme': isVellumTheme,
      'isBiometricEnabled': isBiometricEnabled,
      'monthlyBudgetPaise': monthlyBudgetPaise,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      currency: json['currency'] as String? ?? 'INR',
      weekStartsOn: json['weekStartsOn'] as int? ?? 1,
      monthStartDay: json['monthStartDay'] as int? ?? 1,
      isVellumTheme: json['isVellumTheme'] as bool? ?? false,
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
      monthlyBudgetPaise: json['monthlyBudgetPaise'] as int?,
    );
  }
}

