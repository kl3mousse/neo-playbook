/// A link to a user's profile on an external site or social network.
///
/// Both [url] and [username] are required. The UI can recognize known
/// hosts to display a brand icon; see `lib/widgets/social_link_icons.dart`.
class SocialLink {
  final String url;
  final String username;

  const SocialLink({required this.url, required this.username});

  bool get isValid => url.trim().isNotEmpty && username.trim().isNotEmpty;

  factory SocialLink.fromMap(Map<String, dynamic> map) {
    return SocialLink(
      url: (map['url'] as String? ?? '').trim(),
      username: (map['username'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'url': url.trim(),
        'username': username.trim(),
      };

  SocialLink copyWith({String? url, String? username}) => SocialLink(
        url: url ?? this.url,
        username: username ?? this.username,
      );
}
