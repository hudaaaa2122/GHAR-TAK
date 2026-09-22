/// Static copy adapted from Gher Tak website Figma (mobile).
class InfoContactCard {
  const InfoContactCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final String icon; // email | phone | place
}

class InfoSection {
  const InfoSection({required this.title, required this.body, this.bullets});

  final String title;
  final String body;
  final List<String>? bullets;
}

class FaqItem {
  const FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;
}

class AboutTab {
  const AboutTab({required this.label, required this.heading, required this.body});

  final String label;
  final String heading;
  final String body;
}

class AboutValue {
  const AboutValue({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final String icon;
  final int color;
}

class InfoContent {
  InfoContent._();

  static const contactCards = [
    InfoContactCard(
      title: 'Support Email',
      value: 'info@ghertak.com',
      icon: 'email',
    ),
    InfoContactCard(
      title: 'Customer Service',
      value: '(+92) 42 111 700 700',
      icon: 'phone',
    ),
    InfoContactCard(
      title: 'Office Address',
      value: 'Islamabad, Pakistan',
      icon: 'place',
    ),
  ];

  static const termsEffective = 'EFFECTIVE DATE: NOVEMBER 1, 2023';

  static const termsSections = [
    InfoSection(
      title: '1. Use of Our Services',
      body:
          'By accessing Gher Tak you agree to use our platform lawfully and responsibly. You must provide accurate account information and keep your login credentials secure.',
    ),
    InfoSection(
      title: '2. Placing Orders',
      body:
          'Orders placed through the app or website are offers to purchase. We may accept, decline, or partially fulfill orders based on stock and delivery coverage.',
    ),
    InfoSection(
      title: '3. Pricing and Payments',
      body:
          'Prices are shown in Pakistani Rupees and may change without notice. Payment methods include cash on delivery and supported digital wallets where available.',
    ),
    InfoSection(
      title: '4. Delivery',
      body:
          'Delivery times are estimates. Risk of loss passes to you upon delivery to the address provided. Someone must be available to receive perishable goods.',
    ),
    InfoSection(
      title: '5. Cancellations & Returns',
      body:
          'You may cancel before dispatch where shown in the app. Returns for damaged or incorrect items must be reported promptly with order details.',
    ),
    InfoSection(
      title: '6. Product Information',
      body:
          'We strive for accurate descriptions and images. Slight variations in packaging or weight may occur. Always check expiry dates on receipt.',
    ),
    InfoSection(
      title: '7. User Conduct',
      body:
          'Do not misuse the platform, attempt unauthorized access, or submit abusive content. We may suspend accounts that violate these terms.',
    ),
    InfoSection(
      title: '8. Intellectual Property',
      body:
          'Gher Tak branding, app design, and content are protected. You may not copy or redistribute our materials without written permission.',
    ),
    InfoSection(
      title: '9. Limitation of Liability',
      body:
          'To the fullest extent permitted by law, Gher Tak is not liable for indirect or consequential losses arising from use of the service.',
    ),
    InfoSection(
      title: '10. Privacy',
      body:
          'Your use of Gher Tak is also governed by our Privacy Policy, which explains how we collect and use personal data.',
    ),
    InfoSection(
      title: '11. Changes to Terms',
      body:
          'We may update these Terms periodically. Continued use after changes means you accept the revised Terms.',
    ),
    InfoSection(
      title: '12. Governing Law',
      body:
          'These Terms are governed by the laws of Pakistan. Disputes shall be subject to the courts of Islamabad / Lahore as applicable.',
    ),
    InfoSection(
      title: '13. Contact',
      body:
          'For questions about these Terms, contact our support team using the details below.',
    ),
    InfoSection(
      title: '14. Entire Agreement',
      body:
          'These Terms, together with our Privacy Policy and any order-specific terms, constitute the entire agreement between you and Gher Tak.',
    ),
  ];

  static const privacyUpdated = 'Last updated: November 1, 2023';

  static const privacySections = [
    InfoSection(
      title: '1. Information We Collect',
      body: 'We collect information you provide and data generated while using Gher Tak.',
      bullets: [
        'Personal information: name, phone, email, delivery address',
        'Order and payment-related details',
        'Device, IP, and approximate location data',
      ],
    ),
    InfoSection(
      title: '2. How We Use Your Information',
      body:
          'We use your information to process orders, provide customer support, improve the app, send service updates, and comply with legal obligations.',
    ),
    InfoSection(
      title: '3. How We Share Your Information',
      body:
          'We share data with delivery partners, payment processors, and service providers who help operate Gher Tak. We may disclose information when required by law.',
    ),
    InfoSection(
      title: '4. Cookies and Tracking',
      body:
          'We use cookies and similar technologies to remember preferences, measure performance, and personalize content.',
    ),
    InfoSection(
      title: '5. Data Security',
      body:
          'We apply reasonable technical and organizational measures to protect your data. No method of transmission is 100% secure.',
    ),
    InfoSection(
      title: '6. Your Rights',
      body:
          'Subject to applicable law, you may request access, correction, or deletion of your personal data by contacting support.',
    ),
    InfoSection(
      title: '7. Data Retention',
      body:
          'We retain information for as long as needed to provide services, meet legal requirements, and resolve disputes.',
    ),
    InfoSection(
      title: '8. Children\'s Privacy',
      body:
          'Gher Tak is not directed to children under 13. We do not knowingly collect personal information from children.',
    ),
    InfoSection(
      title: '9. Updates to This Policy',
      body:
          'We may update this Privacy Policy from time to time. We will post the revised version with an updated date.',
    ),
    InfoSection(
      title: '10. Contact Us',
      body:
          'For privacy questions, reach us at info@ghertak.com or via the Contact Us screen in the app.',
    ),
  ];

  static const privacyLegalNote =
      'Gher Tak aims to align with applicable Pakistani data protection principles, including the spirit of the Personal Data Protection Bill, 2019, as practices evolve.';

  static const faqCategories = [
    'General',
    'Billing & Payments',
    'Fulfillment',
    'Technical Support',
  ];

  static const faqs = [
    FaqItem(
      category: 'General',
      question: 'How do I place an order?',
      answer:
          'Browse products, add items to your cart, choose a delivery address, and confirm checkout. You can pay by cash on delivery or supported digital methods.',
    ),
    FaqItem(
      category: 'Fulfillment',
      question: 'What areas do you deliver to?',
      answer:
          'We currently deliver across major service areas in Pakistan. Enter your address in the app to confirm coverage for your location.',
    ),
    FaqItem(
      category: 'Fulfillment',
      question: 'What are your delivery hours?',
      answer:
          'Delivery windows vary by city. Typical same-day slots run during daytime and early evening; check the app for live availability.',
    ),
    FaqItem(
      category: 'Billing & Payments',
      question: 'Is there a minimum order amount?',
      answer:
          'A small minimum may apply in some areas. Free delivery applies on orders over the amount configured in store settings (currently Rs. 3,000 on production).',
    ),
    FaqItem(
      category: 'Fulfillment',
      question: 'Can I modify or cancel my order after placing it?',
      answer:
          'You can cancel before the order is dispatched from the My Orders screen. After dispatch, contact support for assistance.',
    ),
    FaqItem(
      category: 'Fulfillment',
      question: 'What if an item I ordered is out of stock?',
      answer:
          'We may substitute with a similar item (if you allow) or refund the missing item. You will be notified in the app.',
    ),
    FaqItem(
      category: 'General',
      question: 'How is the freshness of products ensured?',
      answer:
          'We partner with trusted suppliers and follow cold-chain practices for perishables. Please inspect items on delivery.',
    ),
    FaqItem(
      category: 'Billing & Payments',
      question: 'Damage Product Return',
      answer:
          'Report damaged products within the timeframe shown on your order. Share photos via support and we will arrange a return or refund.',
    ),
    FaqItem(
      category: 'Technical Support',
      question: 'The app is crashing or not loading. What should I do?',
      answer:
          'Update to the latest version, check your internet connection, and restart the app. If issues continue, contact technical support with your device model.',
    ),
  ];

  static const aboutIntro =
      'We exist to transform household shopping through technology and a human touch — making daily essentials faster, fairer, and more reliable for every family we serve.';

  static const aboutTabs = [
    AboutTab(
      label: 'Our Mission',
      heading: 'Empowering Progress Through Innovation',
      body:
          'Our mission is to provide cutting-edge commerce tools for sellers and a delightful, dependable shopping experience for customers — from search to doorstep.',
    ),
    AboutTab(
      label: 'Our Vision',
      heading: 'Everyday needs, delivered with care',
      body:
          'We envision a Pakistan where grocery and household essentials arrive quickly, transparently, and affordably — powered by local partners and smart logistics.',
    ),
    AboutTab(
      label: 'Our everyday LIFE',
      heading: 'Built for real households',
      body:
          'From morning milk runs to late-night medicine needs, Gher Tak is designed around the rhythms of everyday life across grocery, pharmacy, bakery, and business verticals.',
    ),
    AboutTab(
      label: 'Our Culture',
      heading: 'Customer-obsessed and kind',
      body:
          'We hire for ownership, curiosity, and respect. Teams collaborate closely with riders, sellers, and support agents to keep promises made in the app.',
    ),
    AboutTab(
      label: 'Leadership We Demonstrate',
      heading: 'Lead by serving',
      body:
          'Leaders at Gher Tak set clear goals, listen to frontline feedback, and make decisions that protect customer trust and partner livelihoods.',
    ),
    AboutTab(
      label: 'Our People',
      heading: 'The heart of Gher Tak',
      body:
          'Our people — warehouse teams, riders, engineers, and support — make every order possible. We invest in training, safety, and fair opportunity.',
    ),
  ];

  static const aboutValues = [
    AboutValue(
      title: 'Excellence',
      body: 'We sweat the details so every delivery feels reliable.',
      icon: 'trophy',
      color: 0xFFE91E63,
    ),
    AboutValue(
      title: 'Collaboration',
      body: 'We win together with sellers, riders, and customers.',
      icon: 'handshake',
      color: 0xFFFF9800,
    ),
    AboutValue(
      title: 'Innovation',
      body: 'We improve search, logistics, and UX continuously.',
      icon: 'bulb',
      color: 0xFF2196F3,
    ),
    AboutValue(
      title: 'Integrity',
      body: 'We communicate clearly and do what we say.',
      icon: 'shield',
      color: 0xFF4CAF50,
    ),
  ];

  static const aboutStats = [
    ('50K+', 'Happy customers'),
    ('2,000+', 'Products listed'),
    ('120+', 'Cities served'),
    ('<1hr', 'Average delivery time'),
  ];
}
