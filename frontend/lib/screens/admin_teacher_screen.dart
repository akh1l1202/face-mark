// admin_teacher_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class AdminTeacherScreen extends StatefulWidget {
  const AdminTeacherScreen({super.key});

  @override
  State<AdminTeacherScreen> createState() => _AdminTeacherScreenState();
}

class _AdminTeacherScreenState extends State<AdminTeacherScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  List<File> _capturedImages = [];
  bool _loading = false;
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final list = await ApiService.listTeachers();
      setState(() {
        _teachers = list;
      });
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _capturedImages.add(File(picked.path));
      });
    }
  }

  Future<void> _registerTeacher() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();

    if (id.isEmpty || name.isEmpty || _capturedImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID, name and at least 2 photos required')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await ApiService.registerTeacher(
        teacherId: id,
        name: name,
        images: _capturedImages,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered: ${result['name']}')),
      );

      _idController.clear();
      _nameController.clear();
      setState(() {
        _capturedImages = [];
      });

      await _loadTeachers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _deleteTeacher(String teacherId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete $teacherId from backend?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteTeacher(teacherId);
      await _loadTeachers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Register / Update Teacher',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(labelText: 'Teacher ID'),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Teacher Name'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: _captureImage,
                child: const Text('Capture Face Photo'),
              ),
              Text('Photos: ${_capturedImages.length}'),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _registerTeacher,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Register / Update Backend'),
          ),
          const Divider(height: 32),
          const Text(
            'Teachers in Backend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ..._teachers.map((t) {
            final id = t['teacherId'] as String;
            final name = t['name'] as String;
            final numEmb = t['numEmbeddings'] as int;
            return ListTile(
              title: Text('$name ($id)'),
              subtitle: Text('Embeddings: $numEmb'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteTeacher(id),
              ),
            );
          }),
        ],
      ),
    );
  }
}
