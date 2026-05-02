import 'package:flutter/material.dart';
import '../core/constants.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: Color(AppColors.primaryOrange),
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(AppColors.primaryOrange),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/google_logo.png',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.language,
                      size: 24,
                      color: Color(AppColors.primaryOrange),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.darkText),
                  ),
                ),
              ],
            ),
    );
  }
}

