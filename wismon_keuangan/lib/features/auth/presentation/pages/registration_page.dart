import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import '../bloc/registration_state.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RegistrationBloc(), // We'll inject this properly later
      child: const _RegistrationPageContent(),
    );
  }
}

class _RegistrationPageContent extends StatefulWidget {
  const _RegistrationPageContent();

  @override
  State<_RegistrationPageContent> createState() =>
      _RegistrationPageContentState();
}

class _RegistrationPageContentState extends State<_RegistrationPageContent> {
  final PageController _pageController = PageController();
  int _currentStage = 0;

  // Stage 1 controllers
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _nrmController = TextEditingController();
  final _tglahirController = TextEditingController();

  // Stage 2 controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Form keys
  final _stage1FormKey = GlobalKey<FormState>();
  final _stage2FormKey = GlobalKey<FormState>();

  // Stage 1 verified data
  Map<String, dynamic>? _verifiedStudentData;

  @override
  void dispose() {
    _pageController.dispose();
    _namaController.dispose();
    _nimController.dispose();
    _nrmController.dispose();
    _tglahirController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onStage1Submit() {
    if (_stage1FormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<RegistrationBloc>().add(
        VerifyIdentityEvent(
          nama: _namaController.text.trim(),
          nim: _nimController.text.trim(),
          nrm: _nrmController.text.trim(),
          tglahir: _tglahirController.text.trim(),
        ),
      );
    }
  }

  void _onStage2Submit() {
    if (_stage2FormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      // Use verified data from Stage 1
      final studentData = _verifiedStudentData!;
      context.read<RegistrationBloc>().add(
        CreateAccountEvent(
          nama: studentData['nama'],
          nim: studentData['nim'],
          nrm: studentData['nrm'],
          tglahir: _tglahirController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _goToStage2(Map<String, dynamic> studentData) {
    setState(() {
      _verifiedStudentData = studentData;
      _currentStage = 1;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goBackToStage1() {
    setState(() {
      _currentStage = 0;
      _verifiedStudentData = null;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state is RegistrationError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
        } else if (state is IdentityVerified) {
          _goToStage2(state.studentData);
        } else if (state is AccountCreated) {
          _showSuccessDialog(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Registrasi - Tahap ${_currentStage + 1}'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentStage == 0) {
                Navigator.of(context).pop();
              } else {
                _goBackToStage1();
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Verifikasi'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStage >= 1
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                  ),
                  _buildStepIndicator(1, 'Akun'),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStage1Form(), _buildStage2Form()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step <= _currentStage;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStage1Form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stage1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verifikasi Data Mahasiswa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan data Anda untuk verifikasi sebagai mahasiswa yang terdaftar',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama lengkap harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nimController,
              decoration: const InputDecoration(
                labelText: 'NIM',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'NIM harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nrmController,
              decoration: const InputDecoration(
                labelText: 'NRM',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'NRM harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tglahirController,
              decoration: const InputDecoration(
                labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                hintText: '1995-01-15',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tanggal lahir harus diisi';
                }
                if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                  return 'Format tanggal harus YYYY-MM-DD';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            BlocBuilder<RegistrationBloc, RegistrationState>(
              builder: (context, state) {
                final isLoading = state is RegistrationLoading;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading ? null : _onStage1Submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lanjut'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage2Form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stage2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Buat Akun',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat username dan password untuk akun Anda',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_verifiedStudentData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Terverifikasi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Nama: ${_verifiedStudentData!['nama']}'),
                    Text('NIM: ${_verifiedStudentData!['nim']}'),
                    Text('NRM: ${_verifiedStudentData!['nrm']}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle),
                hintText: 'Hanya huruf dan angka',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username harus diisi';
                }
                if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                  return 'Username hanya boleh mengandung huruf dan angka';
                }
                if (value.length < 3) {
                  return 'Username minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email harus diisi';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password harus diisi';
                }
                if (value.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            BlocBuilder<RegistrationBloc, RegistrationState>(
              builder: (context, state) {
                final isLoading = state is RegistrationLoading;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading ? null : _onStage2Submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.email, size: 48, color: Colors.green),
        title: const Text('Registrasi Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
