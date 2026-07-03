import 'package:flutter/material.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design_system/design_system.dart';
import 'legal_documents.dart';

enum LegalDocumentType { privacy, terms }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  String get _title => switch (type) {
        LegalDocumentType.privacy => LegalDocuments.privacyPolicyTitle,
        LegalDocumentType.terms => LegalDocuments.termsTitle,
      };

  String get _body => switch (type) {
        LegalDocumentType.privacy => LegalDocuments.privacyPolicyBody,
        LegalDocumentType.terms => LegalDocuments.termsBody,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return AppScaffold(
      title: _title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: SelectableText(
          _body.trim(),
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: tokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
