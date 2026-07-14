import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final authUser = ref.read(authStateProvider).valueOrNull;

    _nameController = TextEditingController(
      text: profile?.fullName ?? authUser?.displayName ?? '',
    );
    _emailController = TextEditingController(
      text: profile?.email ?? authUser?.email ?? '',
    );
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final theme = Theme.of(context);

    final avatarUrl = profile?.avatarUrl ?? authUser?.photoURL;
    final displayName = _nameController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            backgroundImage: _avatarImage(avatarUrl),
                            child: _avatarImage(avatarUrl) == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isSaving ? null : _pickAvatar,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Chạm biểu tượng camera để đổi ảnh đại diện',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      prefixIconColor: Colors.white38,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.email_outlined),
                      prefixIconColor: Colors.white38,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'Tùy chọn',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      prefixIconColor: Colors.white38,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Giới thiệu',
                      hintText: 'Viết vài dòng về bạn...',
                      alignLabelWithHint: true,
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.notes_rounded),
                      prefixIconColor: Colors.white38,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(String? avatarUrl) {
    if (_pickedImageBytes != null) {
      return MemoryImage(_pickedImageBytes!);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }
    return null;
  }

  Future<void> _pickAvatar() async {
    final file = await ref.read(userProfileServiceProvider).pickAvatarImage();
    if (file == null || !mounted) {
      return;
    }

    final bytes = await file.readAsBytes();
    setState(() {
      _pickedImage = file;
      _pickedImageBytes = bytes;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(userProfileServiceProvider).saveProfile(
            fullName: _nameController.text,
            phone: _phoneController.text,
            bio: _bioController.text,
            avatarFile: _pickedImage,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? 'Lỗi xác thực: ${error.code}';
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Dữ liệu không hợp lệ.';
    }
    final message = error.toString();
    if (message.contains('unauthorized') || message.contains('permission')) {
      return 'Không có quyền lưu ảnh. Hãy deploy storage.rules lên Firebase.';
    }
    return 'Không thể lưu hồ sơ: $message';
  }
}
