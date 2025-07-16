import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final Connectivity _connectivity = Connectivity();

  String userName = "Loading...";
  String userEmail = "Loading...";
  String? _profileImageUrl;
  File? _profileImage;
  bool isLoading = true;
  bool isOffline = false;
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
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _loadUserData();

    // Pre-cache images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var image in defaultImages) {
        precacheImage(AssetImage(image), context);
      }
    });
  }

  Future<void> _initConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not check connectivity status');
      }
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (mounted) {
      setState(() {
        isOffline = result == ConnectivityResult.none;
        if (isOffline) {
          _errorMessage = 'No internet connection';
        } else if (_errorMessage == 'No internet connection') {
          _errorMessage = '';
          _loadUserData(); // Retry loading data when connection is restored
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    if (isOffline) return;

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
            _errorMessage = '';
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

  Widget _buildShimmerLoading() {
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
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 28,
                width: 150,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 18,
                width: 200,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const Spacer(),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 24,
                width: 100,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoInternetView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/network_error.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initConnectivity,
              child: const Text('Retry'),
            ),
          ],
        ),
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
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: defaultImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final img = defaultImages[index];
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
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
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _pickImage() async {
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection available')),
      );
      return;
    }

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
    if (isOffline) {
      return _buildNoInternetView();
    }

    if (isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Profile",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/network_error.json',
                width: 150,
                height: 150,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 12),
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