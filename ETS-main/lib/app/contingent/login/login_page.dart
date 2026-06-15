import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/contingent/main.dart';
import 'package:malhar_ets/app/contingent/auth/contingent_controller.dart';
import 'package:malhar_ets/constants/app_bar.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:malhar_ets/helpers/glass_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController(
    text: '',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '',
  );
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: getAppBar(context, false),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1.0 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Contingent/PRNC Login",
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                LiquidGlassContainer(
                  glowColor: AppColors.accent,
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _usernameController,
                            label: "Username",
                            hint: "Enter your username",
                            focusNode: _usernameFocus,
                            autofillHint: AutofillHints.username,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            hint: "Enter your password",
                            obscureText: true,
                            focusNode: _passwordFocus,
                            autofillHint: AutofillHints.password,
                          ),
                          const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            AppFeedback.showLoading(
                              context,
                              message: 'Authenticating...',
                            );

                            try {
                              final result =
                                  await ContingentController.loginAsContingent(
                                    _usernameController.text,
                                    _passwordController.text,
                                  );
                              if (!mounted) return;

                              AppFeedback.hideLoading(context);

                               if (result['success']) {
                                 // Finish autofill context if used
                                 TextInput.finishAutofillContext();
                                 await SessionManager.saveContingentSession(result['contingent']);

                                 AppFeedback.showSuccess(
                                   context,
                                   result['message'],
                                 );

                                 if (context.mounted) {
                                   Navigator.pushReplacement(
                                     context,
                                     MaterialPageRoute(
                                       builder:
                                           (_) => Main(
                                             contingent: result['contingent'],
                                           ),
                                     ),
                                   );
                                 }
                               } else {
                                AppFeedback.showError(
                                  context,
                                  result['message'],
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              AppFeedback.hideLoading(context);
                              AppFeedback.showError(
                                context,
                                'An error occurred: $e',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 50,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            "Login",
                            style: GoogleFonts.montserrat(
                              color: AppColors.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.montserrat(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'malhar.admin@xaviers.edu.in',
                          query:
                              'subject=Contingent Login Query&body=Hey, I am having trouble Logging In.',
                        );

                        if (await canLaunchUrl(emailLaunchUri)) {
                          await launchUrl(emailLaunchUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch email app'),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Contact Admin",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FocusNode focusNode,
    bool obscureText = false,
    String? autofillHint,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(color: AppColors.textWhite),
      obscureText: (obscureText) ? _obscurePassword : false,
      autofillHints: autofillHint != null ? [autofillHint] : null,
      onTap: () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        } else {
          focusNode.unfocus();
          Future.delayed(const Duration(milliseconds: 50), () {
            focusNode.requestFocus();
          });
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.textSecondary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        suffixIconColor: AppColors.textWhite,
        suffixIcon:
            (!obscureText)
                ? const Icon(Icons.person)
                : IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                    focusNode.requestFocus();
                  },
                ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
