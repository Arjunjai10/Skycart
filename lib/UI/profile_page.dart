import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String userName = "Loading...";
  String userEmail = "Loading...";
  String? _profileImageUrl;
  File? _profileImage;
  bool isLoading = true;
  String _errorMessage = '';

  final List<String> defaultImages = [
    'assets/default_profile_images/cat.jpeg',
    'assets/default_profile_images/dog.jpeg',
    'assets/default_profile_images/panda.jpeg',
    'assets/default_profile_images/rabit.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Pre-cache images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var image in defaultImages) {
        precacheImage(AssetImage(image), context);
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _userService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            userName = userData['name'] ?? user.displayName ?? 'User';
            userEmail = userData['email'] ?? user.email ?? 'No email';
            _profileImageUrl = userData['profileImage'];
          });
        } else {
          await _userService.saveUserData(
              user.uid, user.displayName ?? 'User', user.email ?? '');
          await _loadUserData();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('Choose default avatar'),
            onTap: () {
              Navigator.pop(context);
              _showDefaultImagePicker();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedImage != null) {
      setState(() => isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final imageUrl = await _userService.uploadProfileImage(
          user.uid,
          pickedImage.path,
        );
        await _userService.updateProfileImageUrl(user.uid, imageUrl);

        setState(() {
          _profileImage = File(pickedImage.path);
          _profileImageUrl = imageUrl;
          isLoading = false;
        });
      }
    }
  }

  void _showDefaultImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        // symmetric padding keeps everything nicely spaced
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // little grab handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a profile picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            // ---- Avatar grid ---------------------------------------------------
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: defaultImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,        // 3 per row looks balanced on phones
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,      // makes every tile perfectly square
              ),
              itemBuilder: (context, index) {
                final img = defaultImages[index];
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);       // close sheet
                    setState(() => isLoading = true);
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await _userService.updateProfileImageUrl(user.uid, img);
                      setState(() {
                        _profileImageUrl = img;
                        _profileImage = null;
                        isLoading = false;
                      });
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(img, fit: BoxFit.cover),
                  ),
                );
              },
            ),
            // -------------------------------------------------------------------

            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }


  void _showEditProfileSheet() {
    _nameController.text = userName;
    _emailController.text = userEmail;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edit Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => isLoading = true);
                Navigator.pop(context);

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await _userService.updateProfile(
                    user.uid,
                    _nameController.text,
                    _emailController.text,
                  );
                  await _loadUserData();
                }
              },
              icon: const Icon(Icons.save),
              label: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    await _userService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(_errorMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (_profileImageUrl != null
                    ? (_profileImageUrl!.startsWith('assets/')
                    ? AssetImage(_profileImageUrl!) as ImageProvider
                    : NetworkImage(_profileImageUrl!))
                    : null),
                child: _profileImage == null && _profileImageUrl == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(userName,
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(userEmail,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showEditProfileSheet,
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Logout",
                  style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
