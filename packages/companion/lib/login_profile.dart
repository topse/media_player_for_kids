import 'dart:convert';

class LoginProfile {
  final String url;
  final String username;
  final String password;

  LoginProfile({
    required this.url,
    required this.username,
    required this.password,
  });

  /// Composite key for deduplication: same url + username = same profile.
  String get key => '$url\n$username';

  Map<String, dynamic> toJson() => {
        'url': url,
        'username': username,
        'password': password,
      };

  factory LoginProfile.fromJson(Map<String, dynamic> json) => LoginProfile(
        url: json['url'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
      );

  LoginProfile copyWith({String? url, String? username, String? password}) =>
      LoginProfile(
        url: url ?? this.url,
        username: username ?? this.username,
        password: password ?? this.password,
      );

  static String encode(List<LoginProfile> profiles) =>
      jsonEncode(profiles.map((p) => p.toJson()).toList());

  static List<LoginProfile> decode(String json) =>
      (jsonDecode(json) as List<dynamic>)
          .map((e) => LoginProfile.fromJson(e as Map<String, dynamic>))
          .toList();
}
