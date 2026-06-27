// lib/screens/register_teacher_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class RegisterTeacherScreen extends StatefulWidget {
  const RegisterTeacherScreen({super.key});

  @override
  State<RegisterTeacherScreen> createState() => _RegisterTeacherScreenState();
}

class _RegisterTeacherScreenState extends State<RegisterTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  int _profileIndex = 0;
  bool _loading = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- Logic Section ---

  Future<void> _captureImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _images.add(File(picked.path));
          // If this is the first image, make it profile automatically
          if (_images.length == 1) {
            _profileIndex = 0;
          } else {
            _profileIndex = _images.length - 1; // Or set latest as profile
          }
        });
      }
    } catch (e) {
      _showSnack('Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        setState(() {
          _images.addAll(picked.map((x) => File(x.path)));
          if (_images.isNotEmpty && _profileIndex >= _images.length) _profileIndex = 0;
        });
      }
    } catch (e) {
      _showSnack('Gallery pick failed: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) {
        _profileIndex = 0;
      } else if (_profileIndex >= index) {
        // Shift index down if we removed an image before or at the current profile index
        _profileIndex = (_profileIndex == 0) ? 0 : _profileIndex - 1;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      _showSnack('Please capture at least one face photo.');
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.registerTeacher(
        teacherId: _idController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        images: _images,
        profileIndex: _profileIndex,
      );

      _showSnack('Teacher Registered Successfully!');
      _clearForm();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearForm() {
    _idController.clear();
    _nameController.clear();
    _phoneController.clear();
    setState(() {
      _images.clear();
      _profileIndex = 0;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // --- UI Components ---

  Widget _buildGlassSection({required Widget child, required String title, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, color: Colors.orangeAccent, size: 18), const SizedBox(width: 8)],
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orangeAccent),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (isPhone && v.length < 10) return 'Invalid phone number';
          return null;
        },
      ),
    );
  }

  Widget _buildPhotoList() {
    if (_images.isEmpty) {
      return GestureDetector(
        onTap: _captureImage,
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
            color: Colors.black12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.add_a_photo_outlined, color: Colors.orangeAccent, size: 32),
              ),
              const SizedBox(height: 12),
              const Text("No faces captured yet", style: TextStyle(color: Colors.white54)),
              const Text("Tap to open camera", style: TextStyle(color: Colors.white30, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _images.length + 1, // +1 for the "Add" button
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // The "Add New" Button at the start (or end, putting it at start here for access)
          if (index == 0) {
            return GestureDetector(
              onTap: _captureImage,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white70, size: 30),
                    SizedBox(height: 4),
                    Text("Add", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          final imageIndex = index - 1;
          final file = _images[imageIndex];
          final isProfile = imageIndex == _profileIndex;

          return GestureDetector(
            onTap: () => setState(() => _profileIndex = imageIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isProfile
                    ? Border.all(color: Colors.orangeAccent, width: 2)
                    : Border.all(color: Colors.white12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                  // Delete Button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(imageIndex),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                  // Profile Badge
                  if (isProfile)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 10, color: Colors.black),
                              SizedBox(width: 4),
                              Text("PROFILE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Assumes parent has background/gradient
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra bottom padding for FAB/Scroll
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Personal Details Section
              _buildGlassSection(
                title: 'Teacher Details',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    _buildTextField(controller: _idController, label: 'Teacher ID', icon: Icons.badge_outlined),
                    _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person),
                    _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_android, isPhone: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Face Data Section
              _buildGlassSection(
                title: 'Face Verification Data',
                icon: Icons.face_retouching_natural,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Captured Photos (${_images.length})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library, size: 16, color: Colors.white54),
                          label: const Text("Gallery", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPhotoList(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Submit Button
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                  shadowColor: Colors.orangeAccent.withOpacity(0.4),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("REGISTER TEACHER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}