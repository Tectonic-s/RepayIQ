import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shows a full-screen success overlay: progress bar fills → tick appears → auto-dismisses.
/// Awaiting this future means the caller can navigate after it completes.
Future<void> showLoanSavedOverlay(BuildContext context, {String message = 'Loan added successfully', Color? iconColor}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, anim, secondary, child) =>
        FadeTransition(opacity: anim, child: child),
    pageBuilder: (ctx, a, b) => _LoanSavedOverlay(message: message, iconColor: iconColor),
  );
}

class _LoanSavedOverlay extends StatefulWidget {
  final String message;
  final Color? iconColor;
  const _LoanSavedOverlay({required this.message, this.iconColor});
  @override
  State<_LoanSavedOverlay> createState() => _LoanSavedOverlayState();
}

class _LoanSavedOverlayState extends State<_LoanSavedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;
  late final Animation<double> _tickScale;
  bool _showTick = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _progress = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeInOut));
    _tickScale = CurvedAnimation(parent: _ctrl, curve: const Interval(0.65, 1.0, curve: Curves.elasticOut));
    _ctrl.forward().then((_) {
      if (mounted) setState(() => _showTick = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 8))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72, height: 72,
                  child: CircularProgressIndicator(
                    value: _progress.value,
                    strokeWidth: 5,
                    backgroundColor: (widget.iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(widget.iconColor ?? AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                if (_showTick)
                  ScaleTransition(
                    scale: _tickScale,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: widget.iconColor ?? AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ]),
      ),
    );
  }
}

/// Wraps any widget with a fade+slide-up transition when its content changes.
/// Use by giving a unique [key] that changes when data changes.
class AnimatedDataSwitch extends StatelessWidget {
  final Widget child;
  const AnimatedDataSwitch({required super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animates a numeric string value with a fade+slide when it changes.
class AnimatedValue extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final TextAlign? textAlign;
  const AnimatedValue(this.value, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(value, key: ValueKey(value), style: style, textAlign: textAlign),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                )
              : Text(label),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
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
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleLogo(),
                const SizedBox(width: 10),
                const Text('Continue with Google'),
              ],
            ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://www.google.com/favicon.ico',
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFB0B7C3) : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          enabled: widget.enabled,
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofocus: widget.autofocus,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: isDark ? const Color(0xFF6B7280) : AppColors.textHint)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: isDark ? const Color(0xFF6B7280) : AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
