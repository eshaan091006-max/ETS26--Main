import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/utils/hash_util.dart';
import 'package:malhar_ets/helpers/glass_container.dart';

class ProfilePage extends StatefulWidget {
  final Contingent contingent;
  const ProfilePage({super.key, required this.contingent});

  @override
  State<ProfilePage> createState() => _ContingentPageState();
}

class _ContingentPageState extends State<ProfilePage> {
  bool _obscurePassword = true;

  late String code;
  late String password;

  @override
  void initState() {
    super.initState();
    code = widget.contingent.contingentCode;
    password = widget.contingent.password;
  }

  void _showEditSheet() {
    final TextEditingController codeController = TextEditingController(
      text: code,
    );
    final TextEditingController passwordController = TextEditingController(
      text: '', // Start empty, do not show hashed password
    );

    bool obscurePassword = true;
    bool hasUpper = false;
    bool hasLower = false;
    bool hasDigit = false;
    bool hasSpecial = false;
    bool hasMinLength = false;
    bool isPasswordValid() {
      return hasUpper && hasLower && hasDigit && hasSpecial && hasMinLength;
    }

    void validatePassword(
      String value,
      void Function(void Function()) setModalState,
    ) {
      setModalState(() {
        hasUpper = RegExp(r'[A-Z]').hasMatch(value);
        hasLower = RegExp(r'[a-z]').hasMatch(value);
        hasDigit = RegExp(r'\d').hasMatch(value);
        hasSpecial = RegExp(r'[!@#\$&*~_]').hasMatch(value);
        hasMinLength = value.length >= 8;
      });
    }

    Widget buildRule(String text, bool isValid) {
      return Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            validatePassword(passwordController.text, setModalState);
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Edit Contingent",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Code (Disabled)
                      TextField(
                        enabled: false,
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: "Contingent Code",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// Password with toggle visibility
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        onChanged:
                            (value) => validatePassword(value, setModalState),
                        decoration: InputDecoration(
                          labelText: "Password",

                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Password rules
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildRule("Min 8 characters", hasMinLength),
                          buildRule("At least 1 uppercase letter", hasUpper),
                          buildRule("At least 1 lowercase letter", hasLower),
                          buildRule("At least 1 number", hasDigit),
                          buildRule(
                            "At least 1 special character (!@#\$&*~_)",
                            hasSpecial,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Save Button
                      ElevatedButton(
                        onPressed: () async {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          if (isPasswordValid()) {
                            setState(() {
                              code = codeController.text;
                              // Do not store plain text password locally
                            });
                            Contingent c = widget.contingent;
                            c.contingentCode = code;
                            c.password = HashUtil.hashPassword(passwordController.text);
                            bool result = await ContingentController()
                                .updateContingent(context, c);

                            (result)
                                ? AppFeedback.showSuccess(
                                  context,
                                  "Password Changed Successfully!",
                                )
                                : AppFeedback.showError(
                                  context,
                                  "Error in Changing Password.",
                                );
                          } else {
                            AppFeedback.showError(
                              context,
                              "Password Requirements not met.",
                            );
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = AppColors.textPrimary;
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LiquidGlassContainer(
              glowColor: AppColors.accent,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Contingent Code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.confirmation_number,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Code:",
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              code,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),

                        IconButton(
                          onPressed: () => _showEditSheet(),
                          icon: Icon(
                            Icons.edit,
                            semanticLabel: 'Change Password',
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Password
                    Row(
                      children: [
                        const Icon(Icons.lock, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          "Password:",
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "••••••••",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }
}
