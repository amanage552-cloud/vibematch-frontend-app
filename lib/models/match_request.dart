class MatchRequest {
  final String name;
  final String gender;
  final String preference;
  final String? profileImageBase64;

  MatchRequest({
    required this.name,
    required this.gender,
    required this.preference,
    this.profileImageBase64,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'name': name,
      'gender': gender,
      'preference': preference,
    };

    if (profileImageBase64 != null) {
      payload['profileImageBase64'] = profileImageBase64;
    }

    return payload;
  }
}
