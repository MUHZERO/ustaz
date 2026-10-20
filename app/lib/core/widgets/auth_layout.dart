import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'brand_header.dart';

/// Brand header, the form's fields grouped on a card, then the actions.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.actions,
    super.key,
  });
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
        ],
      ),
    ),
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: box.maxHeight - AppSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandHeader(title: title, subtitle: subtitle),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg + 4),
                    child: Column(
                      children: [
                        for (final (index, field) in fields.indexed) ...[
                          if (index > 0) const SizedBox(height: AppSpacing.md),
                          field,
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// "No account yet? Create account" on one line.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    required this.question,
    required this.action,
    required this.onPressed,
    super.key,
  });
  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}
