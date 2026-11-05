import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../services/auth_service.dart';
import 'teacher_dashboard.dart';
import 'admin_dashboard.dart';
import 'parent_dashboard.dart'; // Import Parent Dashboard
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper function to get user role and navigate
  Future<void> _navigateBasedOnRole(String email) async {
    // Admin override for you to test
    if (email == 'admin@school.com') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
      return;
    }

    // Fetch user document from Firestore
    var userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
    
    if (userDoc.docs.isNotEmpty) {
      String role = userDoc.docs.first.get('role');
      if (role == 'parent') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboard()));
      }
    } else {
      // If user has no role saved, default to Teacher
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboard()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.school, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Student Attendance Tracker',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter email and password')),
                      );
                      return;
                    }

                    setState(() { _isLoading = true; });

                    final user = await _authService.signIn(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );

                    if (mounted) {
                      setState(() { _isLoading = false; });
                    }

                    if (user != null) {
                      await _navigateBasedOnRole(_emailController.text.trim());
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login failed. Check your credentials.')),
                        );
                      }
                    }
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                },
                child: const Text('Don\'t have an account? Register here', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}