import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
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
  bool _deletingAccount = false;

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

  Future<bool> _confirmDeleteAccount() async {
    final typed = TextEditingController();
    var loading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = typed.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              title: const Text('Delete account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will permanently remove your profile and user data. '
                    'Type DELETE to confirm.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typed,
                    enabled: !loading,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: (!canDelete || loading)
                      ? null
                      : () async {
                          setDialogState(() => loading = true);
                          Navigator.pop(context, true);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    typed.dispose();
    return result ?? false;
  }

  Future<void> _deleteAccount() async {
    if (_deletingAccount) return;
    setState(() => _deletingAccount = true);
    try {
      await UserService.deleteCurrentAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Account deletion failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _deletingAccount = false);
      }
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
                      ? Text(
                          avatarLabel,
                          style: const TextStyle(fontSize: 36),
                        )
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
                          ),
                        );
                    if (updated != null) {
                      setState(() => _loading = true);
                      await UserService.updateProfile(
                        displayName: updated.displayName,
                        photoUrl: updated.photoUrl,
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
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(user?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Member since'),
            subtitle: Text(
              _profile?.createdAt != null
                  ? _profile!.createdAt!.toDate().toString().split(' ')[0]
                  : 'Unknown',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('See how ComboFox handles your data'),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            subtitle: const Text('Report an issue or request a feature'),
            onTap: () => context.push('/feedback'),
          ),
          const Divider(),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () async {
              await AuthService.signOut();
            },
            child: const Text('Sign Out'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _deletingAccount
                ? null
                : () async {
                    final confirmed = await _confirmDeleteAccount();
                    if (!confirmed) return;
                    await _deleteAccount();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: _deletingAccount
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditResult {
  final String displayName;
  final String? photoUrl;
  _ProfileEditResult(this.displayName, this.photoUrl);
}

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String? initialPhotoUrl;
  const _EditProfileSheet({required this.initialName, this.initialPhotoUrl});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  String? _photoUrl;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _photoUrl = widget.initialPhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    setState(() => _saving = true);
    try {
      String? url = _photoUrl;
      if (_pickedImageBytes != null) {
        url = await _uploadImage(_pickedImageBytes!);
      }
      if (mounted) {
        Navigator.pop(
          context,
          _ProfileEditResult(_nameController.text.trim(), url),
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
