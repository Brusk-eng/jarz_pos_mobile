import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/studio_tokens.dart';
import 'studio_tr.dart';

/// An address the Studio does not have: a plain Studio page in both languages
/// with the way back to Today (never the router's bare English one).
class StudioNotFoundScreen extends StatelessWidget {
  const StudioNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('page-not-found'),
    appBar: AppBar(
      title: Text(context.tr('Page not found', 'الصفحة مش موجودة')),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(
                'This address is not a page in the Studio.',
                'العنوان ده مش صفحة في الاستوديو.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: StudioSpacing.lg),
            FilledButton(
              key: const ValueKey('not-found-today'),
              onPressed: () => context.go('/today'),
              child: Text(context.tr('Back to Today', 'ارجع للنهارده')),
            ),
          ],
        ),
      ),
    ),
  );
}
