import 'package:flutter/material.dart';
import '../atoms/gym_button.dart';
import '../molecules/gym_labeled_input.dart';

class GymLoginForm extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;

  const GymLoginForm({
    super.key,
    required this.phoneController,
    required this.passwordController,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      // هنا الـ Form بيستخدم الـ Components اللي تحته من غير ما يعرف تفاصيل ألوانها
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GymLabeledInput(label: 'Phone Number', controller: phoneController),
          const SizedBox(height: 16),
          GymLabeledInput(
            label: 'Password',
            controller: passwordController,
            isPassword: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: GymButton(label: 'Login', onPressed: onLogin),
          ),
        ],
      ),
    );
  }
}
