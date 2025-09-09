class Profile {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? goal;
  final List<String>? interests;
  final String? avatarKey;

  const Profile({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.goal,
    this.interests,
    this.avatarKey,
  });

  bool get onboardingComplete =>
      (goal != null && goal!.isNotEmpty) &&
      (interests != null && interests!.isNotEmpty) &&
      (avatarKey != null && avatarKey!.isNotEmpty);

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
    id: m['id'] as String,
    email: m['email'] as String?,
    firstName: m['first_name'] as String?,
    lastName: m['last_name'] as String?,
    birthDate: m['birth_date'] == null ? null : DateTime.parse(m['birth_date'] as String),
    goal: m['goal'] as String?,
    interests: (m['interests'] as List?)?.map((e) => e.toString()).toList(),
    avatarKey: m['avatar_key'] as String?,
  );
}
