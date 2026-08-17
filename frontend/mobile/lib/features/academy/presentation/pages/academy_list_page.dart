import 'package:flutter/material.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/flat_page.dart';
import '../widgets/my_academies_section.dart';

class AcademyListPage extends StatelessWidget {
  const AcademyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academies')),
      body: FlatPage(
        child: SingleChildScrollView(
          padding: AppBreakpoints.horizontalPadding(
            context,
          ).add(const EdgeInsets.symmetric(vertical: AppSpacing.xl)),
          child: AppBreakpoints.constrain(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: const MyAcademiesSection(),
            ),
          ),
        ),
      ),
    );
  }
}
