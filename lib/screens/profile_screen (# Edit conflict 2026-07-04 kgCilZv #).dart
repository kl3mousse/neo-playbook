import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../models/social_link.dart';
import '../widgets/social_link_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!AuthService.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await UserService.getOrCreateProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Sign in to access your profile',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = AuthService.currentUser;
    final displayName = (_profile?.displayName ?? '').trim();
    final avatarLabel = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar with edit button
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      _profile?.photoUrl != null &&
                          _profile!.photoUrl!.isNotEmpty
                      ? NetworkImage(_profile!.photoUrl!)
                      : null,
                  child:
                      (_profile?.photoUrl == null ||
                          _profile!.photoUrl!.isEmpty)
                      ? Text(avatarLabel, style: const TextStyle(fontSize: 36))
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit Profile',
                  onPressed: () async {
                    final updated =
                        await showModalBottomSheet<_ProfileEditResult>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => _EditProfileSheet(
                            initialName: _profile?.displayName ?? '',
                            initialPhotoUrl: _profile?.photoUrl,
                            initialBio: _profile?.bio ?? '',
                            initialSocialLinks:
                                _profile?.socialLinks ?? const <SocialLink>[],
                          ),
                        );
                    if (updated != null) {
                      setState(() => _loading = true);
                      await UserService.updateProfile(
                        displayName: updated.displayName,
                        photoUrl: updated.photoUrl,
                        bio: updated.bio,
                        socialLinks: updated.socialLinks,
                      );
                      await _loadProfile();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Center(
            child: Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Member since ${_profile?.createdAt != null ? _profile!.createdAt!.toDate().toString().split(' ')[0] : 'Unknown'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          _BioSection(bio: _profile?.bio ?? ''),
          const SizedBox(height: 16),
          _SocialLinksSection(
            links: _profile?.socialLinks ?? const <SocialLink>[],
          ),
        ],
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  final String bio;
  const _BioSection({required this.bio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = bio.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (trimmed.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Add a short bio so other players can learn who you are. '
              'Tap the pencil above to edit your profile.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Text(trimmed, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _SocialLinksSection extends StatelessWidget {
  final List<SocialLink> links;
  const _SocialLinksSection({required this.links});

  Future<void> _open(BuildContext context, String url) async {
    var target = url.trim();
    if (target.isEmpty) return;
    if (!target.contains('://')) target = 'https://$target';
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $target')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (links.isEmpty)
          Text(
            'No links added yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            children: [
              for (final link in links)
                Builder(
                  builder: (context) {
                    final site = recognizeSocialSite(link.url);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        site.icon,
                        color: site.brandColor ?? theme.colorScheme.primary,
                      ),
                      title: Text(link.username),
                      subtitle: Text(
                        site.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _open(context, link.url),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _ProfileEditResult {
  final String displayName;
  final String? photoUrl;
  final String bio;
  final List<SocialLink> socialLinks;
  _ProfileEditResult({
    required this.displayName,
    required this.photoUrl,
    required this.bio,
    required this.socialLinks,
  });
}

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String? initialPhotoUrl;
  final String initialBio;
  final List<SocialLink> initialSocialLinks;
  const _EditProfileSheet({
    required this.initialName,
    this.initialPhotoUrl,
    required this.initialBio,
    required this.initialSocialLinks,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _photoUrl;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _saving = false;
  late List<_SocialLinkDraft> _linkDrafts;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
    _photoUrl = widget.initialPhotoUrl;
    _linkDrafts = widget.initialSocialLinks
        .map((l) => _SocialLinkDraft.fromLink(l))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    for (final d in _linkDrafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImage(Uint8List bytes) async {
    final user = AuthService.currentUser;
    if (user == null) return null;
    final ref = FirebaseStorage.instance.ref().child(
      'profile_pics/${user.uid}.jpg',
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required.')),
      );
      return;
    }
    if (bio.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bio is required.')));
      return;
    }

    final links = <SocialLink>[];
    for (var i = 0; i < _linkDrafts.length; i++) {
      final draft = _linkDrafts[i];
      final url = draft.url.text.trim();
      final username = draft.username.text.trim();
      final hasAny = url.isNotEmpty || username.isNotEmpty;
      if (!hasAny) continue;
      if (url.isEmpty || username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Link #${i + 1}: both URL and username are required.',
            ),
          ),
        );
        return;
      }
      links.add(SocialLink(url: url, username: username));
    }

    setState(() => _saving = true);
    try {
      String? url = _photoUrl;
      if (_pickedImageBytes != null) {
        url = await _uploadImage(_pickedImageBytes!);
      }
      if (mounted) {
        Navigator.pop(
          context,
          _ProfileEditResult(
            displayName: name,
            photoUrl: url,
            bio: bio,
            socialLinks: links,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        setState(() => _saving = false);
      }
    }
  }

  void _addLink() {
    setState(() => _linkDrafts.add(_SocialLinkDraft.empty()));
  }

  void _removeLink(int index) {
    setState(() {
      final removed = _linkDrafts.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: _pickedImageBytes != null
                      ? MemoryImage(_pickedImageBytes!)
                      : (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!) as ImageProvider
                      : null,
                  child:
                      (_photoUrl == null || _photoUrl!.isEmpty) &&
                          _pickedImage == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.photo_camera),
                  onPressed: _pickImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
