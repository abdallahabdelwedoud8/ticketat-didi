import 'package:flutter/material.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/auth_service.dart';
import 'package:eventide/services/language_service.dart';
import 'package:eventide/screens/buyer_dashboard.dart';
import 'package:eventide/screens/organizer_dashboard.dart';
import 'package:eventide/screens/sponsor_dashboard.dart';
import 'package:eventide/screens/security_dashboard.dart';
import 'package:intl/intl.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showRoleSelection = false;
  bool _showProfileSetup = false;
  bool _showGoogleProfileSetup = false;
  String _languageCode = 'fr';
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedNeighborhood;
  UserRole _selectedRole = UserRole.buyer;
  DateTime? _selectedBirthday;
  String? _selectedGender;
  AppUser? _tempGoogleUser;
  
  @override
  void initState() {
    super.initState();
    _languageCode = LanguageService.getLanguage();
  }

  String _t(String key) => Languages.translate(key, _languageCode);

  Future<void> _handleAuth() async {
    // For login, require phone/username and password
    if (_isLogin && (_phoneController.text.isEmpty || _passwordController.text.isEmpty)) {
      _showError('Please fill all fields');
      return;
    }

    // For signup initial step, require name, phone number, and password
    if (!_isLogin && !_showRoleSelection && !_showProfileSetup) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
        _showError('Please enter your name, phone number, and password');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      AppUser? user;
      
      if (_isLogin) {
        user = await AuthService.login(_phoneController.text.trim(), _passwordController.text);
        if (user == null) {
          _showError('Invalid username or password');
          setState(() => _isLoading = false);
          return;
        }
      } else {
        if (!_showRoleSelection) {
          setState(() {
            _showRoleSelection = true;
            _isLoading = false;
          });
          return;
        }
        
        if (!_showProfileSetup) {
          setState(() {
            _showProfileSetup = true;
            _showRoleSelection = false;
            _isLoading = false;
          });
          return;
        }
        
        if (_usernameController.text.trim().isEmpty || _selectedBirthday == null || _selectedGender == null || _selectedNeighborhood == null) {
          _showError('Please complete all profile fields');
          setState(() => _isLoading = false);
          return;
        }
        
        user = await AuthService.signup(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text,
          _selectedRole,
          birthday: _selectedBirthday,
          gender: _selectedGender,
          neighborhood: _selectedNeighborhood,
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        );
        
        if (user == null) {
          _showError('Phone number or username already exists');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (!mounted) return;
      _navigateToDashboard(user.role);
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await AuthService.signInWithGoogle();
      
      if (result == null) {
        _showError('Google Sign-In failed');
        setState(() => _isLoading = false);
        return;
      }
      
      // Check if user already exists (returning user)
      if (result['isExistingUser'] == true) {
        final user = result['user'] as AppUser;
        if (!mounted) return;
        _navigateToDashboard(user.role);
      } else {
        // New Google user - need to collect phone number and profile info
        _tempGoogleUser = result['user'] as AppUser;
        setState(() {
          _showGoogleProfileSetup = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('An error occurred during Google Sign-In');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _completeGoogleProfileSetup() async {
    if (_phoneController.text.trim().isEmpty || _selectedBirthday == null || _selectedGender == null || _selectedNeighborhood == null) {
      _showError('Please complete all fields');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final updatedUser = await AuthService.completeGoogleProfile(
        _tempGoogleUser!,
        _phoneController.text.trim(),
        _selectedBirthday!,
        _selectedGender!,
        _selectedNeighborhood!,
      );
      
      if (updatedUser == null) {
        _showError('Phone number already exists');
        setState(() => _isLoading = false);
        return;
      }
      
      if (!mounted) return;
      _navigateToDashboard(updatedUser.role);
    } catch (e) {
      _showError('An error occurred');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(UserRole role) {
    Widget dashboard;
    
    switch (role) {
      case UserRole.buyer:
        dashboard = const BuyerDashboard();
        break;
      case UserRole.organizer:
        dashboard = const OrganizerDashboard();
        break;
      case UserRole.sponsor:
        dashboard = const SponsorDashboard();
        break;
      case UserRole.security:
        dashboard = const SecurityDashboard();
        break;
      default:
        dashboard = const BuyerDashboard();
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dashboard));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/main_logo.png',
                  height: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appTagline,
                style: const TextStyle(fontSize: 14, color: AppConstants.greyColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (!_isLogin && !_showRoleSelection && !_showProfileSetup) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _t('name'),
                    prefixIcon: const Icon(Icons.person, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!_showRoleSelection && !_showProfileSetup && !_showGoogleProfileSetup) ...[
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: _isLogin ? 'Phone Number or Username' : 'Phone Number',
                    hintText: _isLogin ? 'Enter phone or username' : '+222 XX XX XX XX',
                    prefixIcon: const Icon(Icons.phone, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: _isLogin ? TextInputType.text : TextInputType.phone,
                ),
                const SizedBox(height: 16),
                if (!_isLogin) ...[
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email (optional)',
                      hintText: 'your.email@example.com',
                      prefixIcon: const Icon(Icons.email, color: AppConstants.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: _t('password'),
                    prefixIcon: const Icon(Icons.lock, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
              ],
              if (_showProfileSetup) ...[  
                Text(
                  'Complete Your Profile',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Choose a unique username',
                    prefixIcon: const Icon(Icons.alternate_email, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedNeighborhood,
                  decoration: InputDecoration(
                    labelText: 'Neighborhood',
                    prefixIcon: const Icon(Icons.location_on, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  items: AppConstants.neighborhoods.map((n) {
                    final displayName = _languageCode == 'ar' ? n['ar']! : n['fr']!;
                    return DropdownMenuItem(value: n['fr'], child: Text(displayName));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedNeighborhood = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(Icons.person, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      helpText: 'Select your birthday',
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppConstants.primaryColor,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(foregroundColor: AppConstants.primaryColor),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _selectedBirthday = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake, color: AppConstants.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedBirthday != null ? DateFormat('dd/MM/yyyy').format(_selectedBirthday!) : 'Select birthday',
                            style: TextStyle(
                              color: _selectedBirthday != null ? Colors.black : AppConstants.greyColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: AppConstants.greyColor, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ] else if (_showGoogleProfileSetup) ...[
                Text(
                  'Complete Your Profile',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome ${_tempGoogleUser?.name ?? ''}! Please provide your phone number and details to continue.',
                  style: const TextStyle(fontSize: 14, color: AppConstants.greyColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+222 XX XX XX XX',
                    prefixIcon: const Icon(Icons.phone, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedNeighborhood,
                  decoration: InputDecoration(
                    labelText: 'Neighborhood',
                    prefixIcon: const Icon(Icons.location_on, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  items: AppConstants.neighborhoods.map((n) {
                    final displayName = _languageCode == 'ar' ? n['ar']! : n['fr']!;
                    return DropdownMenuItem(value: n['fr'], child: Text(displayName));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedNeighborhood = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(Icons.person, color: AppConstants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedBirthday = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake, color: AppConstants.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedBirthday != null ? DateFormat('dd/MM/yyyy').format(_selectedBirthday!) : 'Select birthday',
                            style: TextStyle(
                              color: _selectedBirthday != null ? Colors.black : AppConstants.greyColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: AppConstants.greyColor, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ] else if (_showRoleSelection) ...[
                Text(
                  _t('select_role'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildRoleCard(UserRole.buyer, Icons.shopping_bag, _t('buyer')),
                _buildRoleCard(UserRole.organizer, Icons.event, _t('organizer')),
                _buildRoleCard(UserRole.sponsor, Icons.handshake, _t('sponsor')),
                const SizedBox(height: 24),
              ],
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_showGoogleProfileSetup ? _completeGoogleProfileSetup : _handleAuth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppConstants.whiteColor)
                      : Text(
                          _showGoogleProfileSetup ? 'Complete Profile' : (_showProfileSetup ? _t('signup') : (_showRoleSelection ? _t('next') : (_isLogin ? _t('login') : _t('next')))),
                          style: const TextStyle(color: AppConstants.whiteColor, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_showRoleSelection && !_showProfileSetup && !_showGoogleProfileSetup) ...[
                Row(
                  children: [
                    Expanded(child: Divider(color: AppConstants.greyColor.withValues(alpha: 0.3))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: AppConstants.greyColor)),
                    ),
                    Expanded(child: Divider(color: AppConstants.greyColor.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.asset('assets/images/google_logo.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 32)),
                    label: Text(
                      _isLogin ? 'Sign in with Google' : 'Sign up with Google',
                      style: const TextStyle(color: AppConstants.textColor, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!_showRoleSelection && !_showProfileSetup && !_showGoogleProfileSetup)
                Column(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _showRoleSelection = false;
                        _showProfileSetup = false;
                      }),
                      child: Text(
                        _isLogin ? 'Don\'t have an account? Sign up' : 'Already have an account? Login',
                        style: const TextStyle(color: AppConstants.primaryColor),
                      ),
                    ),
                    if (_isLogin)
                      TextButton(
                        onPressed: _showPasswordResetDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                )
              else if (_showProfileSetup)
                TextButton(
                  onPressed: () => setState(() {
                    _showProfileSetup = false;
                    _showRoleSelection = true;
                  }),
                  child: const Text('Back', style: TextStyle(color: AppConstants.primaryColor)),
                )
              else if (_showGoogleProfileSetup)
                TextButton(
                  onPressed: () => setState(() {
                    _showGoogleProfileSetup = false;
                    _tempGoogleUser = null;
                    _phoneController.clear();
                    _selectedNeighborhood = null;
                    _selectedBirthday = null;
                    _selectedGender = null;
                  }),
                  child: const Text('Cancel', style: TextStyle(color: AppConstants.primaryColor)),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _showRoleSelection = false),
                  child: const Text('Back', style: TextStyle(color: AppConstants.primaryColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(UserRole role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : AppConstants.whiteColor,
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : AppConstants.greyColor.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppConstants.primaryColor : AppConstants.greyColor, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 28),
          ],
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? generatedOTP;
    bool otpSent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!otpSent) ...[
                  const Text('Enter your phone number to receive an OTP'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+222 XX XX XX XX',
                      prefixIcon: const Icon(Icons.phone, color: AppConstants.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ] else ...[
                  if (generatedOTP != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        children: [
                          const Text('Your OTP Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(generatedOTP!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 4),
                          const Text('(In production, this will be sent via SMS)', style: TextStyle(fontSize: 10, color: AppConstants.greyColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: otpController,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: const Icon(Icons.security, color: AppConstants.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock, color: AppConstants.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppConstants.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!otpSent) {
                  if (phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your phone number'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  final otp = await AuthService.requestPasswordReset(phoneController.text.trim());
                  if (otp == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number not found'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  setDialogState(() {
                    otpSent = true;
                    generatedOTP = otp;
                  });
                } else {
                  if (otpController.text.trim().isEmpty || newPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  final success = await AuthService.resetPassword(
                    phoneController.text.trim(),
                    otpController.text.trim(),
                    newPasswordController.text,
                  );
                  
                  if (!mounted) return;
                  
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset successfully! You can now login'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              child: Text(otpSent ? 'Reset Password' : 'Send OTP', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
