import 'dart:io';
import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/services/firestore_service.dart'; // ADDED import
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// REMOVED: cloud_firestore.dart and firebase_storage.dart (now handled by service)

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // --- Service ---
  final FirestoreService _firestoreService = FirestoreService(); // ADDED service instance

  // --- State ---
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Function to pick an image (Unchanged)
  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- MODIFIED: _saveProfile function ---
  // This now uses your FirestoreService to match the pharmacy edit page.
  Future<void> _saveProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      String? newImageUrl;

      // 1. If a new image was picked, upload it using the service
      if (_imageFile != null) {
        newImageUrl = await _firestoreService.uploadProfileImage(_imageFile!);
      }

      // 2. Create the updated UserModel
      // We use .copyWith() to create a new model with the changes
      UserModel updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: newImageUrl ?? widget.user.profileImageUrl, // Use new URL or keep old one
        // Email is not updated here as it's read-only
      );

      // 3. Update the user document in Firestore via the service
      await _firestoreService.updateUser(updatedUser);

      // 4. If successful, show snackbar and pop (Unchanged)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This build logic is from your original EditProfilePage (Unchanged)
    ImageProvider currentImage;
    if (_imageFile != null) {
      currentImage = FileImage(_imageFile!);
    } else if (widget.user.profileImageUrl.isNotEmpty) {
      currentImage = NetworkImage(widget.user.profileImageUrl);
    } else {
      // Assuming you have a default avatar image
      currentImage = const AssetImage('assets/images/user_avatar.png');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image Preview and Picker
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: currentImage,
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle broken image links
                    print("Error loading network image: $exception");
                    setState(() {
                      currentImage = const AssetImage('assets/images/user_avatar.png');
                    });
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue, // Blue circle
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _pickImage,
              child: const Text(
                'Change Profile Photo',
                style: TextStyle(color: Color(0xFF0052CC), fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Text Fields
            _buildTextField(
                controller: _nameController,
                labelText: 'Name',
                readOnly: false),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                readOnly: true, // IMPORTANT: Email is read-only
                helperText: 'Email cannot be changed.'),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                readOnly: false,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC), // Blue color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a consistent text field style (Unchanged)
  Widget _buildTextField(
      {required TextEditingController controller,
        required String labelText,
        required bool readOnly,
        String? helperText,
        TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0052CC), width: 2),
        ),
      ),
    );
  }
}