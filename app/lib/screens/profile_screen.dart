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
      if (mounted) setState(() {
        _profile = profile;
        _loading = false;
      });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
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
                  backgroundImage: _profile?.photoUrl != null && _profile!.photoUrl!.isNotEmpty
                      ? NetworkImage(_profile!.photoUrl!)
                      : null,
                  child: (_profile?.photoUrl == null || _profile!.photoUrl!.isEmpty)
                      ? Text(
                          (_profile?.displayName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 36),
                        )
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit Profile',
                  onPressed: () async {
                    final updated = await showModalBottomSheet<_ProfileEditResult>(
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
              _profile?.displayName ?? '',
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
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () async {
              await AuthService.signOut();
            },
            child: const Text('Sign Out'),
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
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
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
    final ref = FirebaseStorage.instance.ref().child('profile_pics/${user.uid}.jpg');
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
        Navigator.pop(context, _ProfileEditResult(_nameController.text.trim(), url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
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
                  child: (_photoUrl == null || _photoUrl!.isEmpty) && _pickedImage == null
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
