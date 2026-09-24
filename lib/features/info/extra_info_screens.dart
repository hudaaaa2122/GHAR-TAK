import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_palette.dart';
import '../providers.dart';
import 'info_content.dart';
import 'info_screens.dart';

class SiteMapScreen extends StatelessWidget {
  const SiteMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InfoScaffold(
      title: 'Sitemap',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'App Sitemap',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete overview of pages in the Gher Tak app. Tap any link to open it.',
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (final section in InfoContent.sitemapSections) ...[
            _SitemapSectionCard(section: section),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SitemapSectionCard extends StatelessWidget {
  const _SitemapSectionCard({required this.section});

  final SitemapSection section;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          title: Text(
            section.title,
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${section.pages.length} pages',
            style: TextStyle(color: p.textMuted, fontSize: 12),
          ),
          children: [
            for (final link in section.pages)
              ListTile(
                dense: true,
                title: Text(
                  link.name,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  link.description,
                  style: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: p.textMuted),
                onTap: () => context.push(link.route),
              ),
          ],
        ),
      ),
    );
  }
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _dept = 'All';

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final depts = [
      'All',
      ...{for (final m in InfoContent.teamMembers) m.department},
    ];
    final members = _dept == 'All'
        ? InfoContent.teamMembers
        : InfoContent.teamMembers.where((m) => m.department == _dept).toList();

    return InfoScaffold(
      title: 'Our Team',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Meet Our Team',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A diverse group of passionate professionals dedicated to delivering exceptional results.',
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in depts)
                ChoiceChip(
                  label: Text(d),
                  selected: _dept == d,
                  onSelected: (_) => setState(() => _dept = d),
                  selectedColor: p.teal,
                  labelStyle: TextStyle(
                    color: _dept == d ? Colors.white : p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final m in members) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: p.tealSoft,
                    child: Text(
                      m.name.isNotEmpty ? m.name[0] : '?',
                      style: TextStyle(
                        color: p.teal,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${m.position} · ${m.department}',
                          style: TextStyle(
                            color: p.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.bio,
                          style: TextStyle(
                            color: p.textSecondary,
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'general';
  String _faqCategory = 'All';
  bool _sending = false;

  static const _categories = [
    ('general', 'General Inquiry'),
    ('billing', 'Billing Issue'),
    ('technical', 'Technical Problem'),
    ('account', 'Account Help'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(accountRepositoryProvider).submitSupport(
            name: name,
            email: email,
            subject: subject,
            message: message,
            category: _category,
          );
      if (!mounted) return;
      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent. We will get back to you soon.'),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chips = ['All', ...InfoContent.faqCategories];
    final faqs = _faqCategory == 'All'
        ? InfoContent.faqs
        : InfoContent.faqs.where((f) => f.category == _faqCategory).toList();

    return InfoScaffold(
      title: 'Support',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Customer Support',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quick answers and a direct line to our team.',
            style: TextStyle(color: p.textSecondary),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in chips) ...[
                  ChoiceChip(
                    label: Text(c),
                    selected: _faqCategory == c,
                    onSelected: (_) => setState(() => _faqCategory = c),
                    selectedColor: p.teal,
                    labelStyle: TextStyle(
                      color: _faqCategory == c ? Colors.white : p.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final f in faqs)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: p.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: p.border),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  f.question,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      f.answer,
                      style: TextStyle(color: p.textSecondary, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(
            'Still need help?',
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: p.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              for (final c in _categories)
                DropdownMenuItem(value: c.$1, child: Text(c.$2)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _message,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _sending ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: p.teal,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_sending ? 'Sending…' : 'Send message'),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.contact),
            child: Text('Contact Us', style: TextStyle(color: p.teal)),
          ),
        ],
      ),
    );
  }
}
