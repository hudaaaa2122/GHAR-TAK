import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/brand_widgets.dart';
import 'info_content.dart';

class InfoScaffold extends StatelessWidget {
  const InfoScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: GherTakLogo(compact: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: child,
    );
  }
}

class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final tiles = [
      (Icons.info_outline_rounded, 'About / Our Purpose', AppRoutes.about),
      (Icons.mail_outline_rounded, 'Contact Us', AppRoutes.contact),
      (Icons.help_outline_rounded, 'FAQ', AppRoutes.faq),
      (Icons.description_outlined, 'Terms & Conditions', AppRoutes.terms),
      (Icons.privacy_tip_outlined, 'Privacy Policy', AppRoutes.privacy),
    ];

    return InfoScaffold(
      title: 'Help Center',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = tiles[i];
          return Material(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: p.tealSoft,
                child: Icon(t.$1, color: p.teal),
              ),
              title: Text(
                t.$2,
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
              onTap: () => context.push(t.$3),
            ),
          );
        },
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InfoScaffold(
      title: 'Terms & Conditions',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Terms & Conditions',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            InfoContent.termsEffective,
            style: TextStyle(
              color: p.teal,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          for (final s in InfoContent.termsSections) ...[
            _SectionCard(title: s.title, body: s.body),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Text(
            'Need help?',
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...InfoContent.contactCards.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ContactInfoCard(card: c),
              )),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InfoScaffold(
      title: 'Privacy Policy',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Privacy Policy',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            InfoContent.privacyUpdated,
            style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (final s in InfoContent.privacySections) ...[
            _SectionCard(title: s.title, body: s.body, bullets: s.bullets),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.tealSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.teal.withValues(alpha: 0.35)),
            ),
            child: Text(
              InfoContent.privacyLegalNote,
              style: TextStyle(
                color: p.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Contact',
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...InfoContent.contactCards.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ContactInfoCard(card: c),
              )),
        ],
      ),
    );
  }
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _category = 'All';
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chips = ['All', ...InfoContent.faqCategories];
    final items = _category == 'All'
        ? InfoContent.faqs
        : InfoContent.faqs.where((f) => f.category == _category).toList();

    return InfoScaffold(
      title: 'FAQ',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find answers about orders, delivery, payments, and more.',
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: p.teal,
                  labelStyle: TextStyle(
                    color: _category == c ? Colors.white : p.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  backgroundColor: p.cardBg,
                  side: BorderSide(color: p.border),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final f in items)
            Card(
              color: p.cardBg,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
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
                      style: TextStyle(
                        color: p.textSecondary,
                        height: 1.45,
                      ),
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
          const SizedBox(height: 6),
          Text(
            'Send us a message and our team will get back to you.',
            style: TextStyle(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          _Field(controller: _name, label: 'Name', palette: p),
          const SizedBox(height: 10),
          _Field(controller: _email, label: 'Email', palette: p),
          const SizedBox(height: 10),
          _Field(
            controller: _message,
            label: 'Message',
            palette: p,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message sent. We will reply soon.'),
                ),
              );
              _name.clear();
              _email.clear();
              _message.clear();
            },
            style: FilledButton.styleFrom(
              backgroundColor: p.teal,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Send message'),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.contact),
            child: Text('Go to Contact Us', style: TextStyle(color: p.teal)),
          ),
        ],
      ),
    );
  }
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/9242111700700');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InfoScaffold(
      title: 'Contact Us',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Get in touch',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Questions about orders, delivery, or your account? We are here to help.',
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...InfoContent.contactCards.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ContactInfoCard(card: c),
              )),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Chat on WhatsApp'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.faq),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.teal,
              side: BorderSide(color: p.teal),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse FAQ'),
          ),
          const SizedBox(height: 22),
          Text(
            'Send a message',
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          _Field(controller: _name, label: 'Full name', palette: p),
          const SizedBox(height: 10),
          _Field(controller: _email, label: 'Email', palette: p),
          const SizedBox(height: 10),
          _Field(controller: _phone, label: 'Phone', palette: p),
          const SizedBox(height: 10),
          _Field(controller: _subject, label: 'Subject', palette: p),
          const SizedBox(height: 10),
          _Field(
            controller: _message,
            label: 'Message',
            palette: p,
            maxLines: 5,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thanks! Your message was submitted.'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: p.teal,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: InfoContent.aboutTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  IconData _valueIcon(String key) {
    return switch (key) {
      'trophy' => Icons.emoji_events_rounded,
      'handshake' => Icons.handshake_rounded,
      'bulb' => Icons.lightbulb_outline_rounded,
      _ => Icons.verified_user_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InfoScaffold(
      title: 'About Us',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Our Purpose',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            InfoContent.aboutIntro,
            style: TextStyle(color: p.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: p.teal,
            unselectedLabelColor: p.textMuted,
            indicatorColor: p.teal,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              for (final t in InfoContent.aboutTabs) Tab(text: t.label),
            ],
            onTap: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (_) {
              final t = InfoContent.aboutTabs[_tabs.index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.heading,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.body,
                      style: TextStyle(color: p.textSecondary, height: 1.45),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            'Our Values',
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: InfoContent.aboutValues.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, i) {
              final v = InfoContent.aboutValues[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(v.color).withValues(alpha: 0.15),
                      child: Icon(_valueIcon(v.icon), color: Color(v.color)),
                    ),
                    const Spacer(),
                    Text(
                      v.title,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.body,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            'By the numbers',
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in InfoContent.aboutStats)
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 42) / 2,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.tealSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          s.$1,
                          style: TextStyle(
                            color: p.teal,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            style: FilledButton.styleFrom(
              backgroundColor: p.teal,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Start shopping'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    this.bullets,
  });

  final String title;
  final String body;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: p.textSecondary, height: 1.45),
          ),
          if (bullets != null) ...[
            const SizedBox(height: 8),
            for (final b in bullets!)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: TextStyle(color: p.teal)),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(color: p.textSecondary, height: 1.4),
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

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.card});

  final InfoContactCard card;

  IconData get _icon => switch (card.icon) {
        'email' => Icons.email_outlined,
        'phone' => Icons.phone_outlined,
        _ => Icons.place_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: p.tealSoft,
            child: Icon(_icon, color: p.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.value,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.palette,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final AppPalette palette;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: palette.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.textMuted),
        filled: true,
        fillColor: palette.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.teal, width: 1.4),
        ),
      ),
    );
  }
}
