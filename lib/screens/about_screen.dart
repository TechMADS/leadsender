// import 'package:flutter/material.dart';
//
// class AboutScreen extends StatelessWidget {
//   const AboutScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('About & Privacy')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: const [
//           Text('LeadSender',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//           SizedBox(height: 8),
//           Text(
//             'A local-only WhatsApp lead messaging assistant. It extracts phone '
//                 'numbers from pasted text, prepares catalogue messages, and opens '
//                 'WhatsApp chats with prefilled text — you always tap Send yourself.',
//           ),
//           SizedBox(height: 16),
//           Text('Privacy',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//           SizedBox(height: 8),
//           Text(
//             '• All phone numbers and lead data stay on your device.\n'
//                 '• Nothing is uploaded to any server.\n'
//                 '• No account, subscription, or login required.\n'
//                 '• You can delete all stored leads from Lead History.\n'
//                 '• The app does not read your WhatsApp messages, contacts, or '
//                 'notifications.',
//           ),
//           SizedBox(height: 16),
//           Text('Responsible Use',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//           SizedBox(height: 8),
//           Text(
//             'Only message people who have agreed to receive promotional '
//                 'communication. LeadSender does not automate WhatsApp, does not '
//                 'press Send, and does not scrape WhatsApp data.',
//           ),
//         ],
//       ),
//     );
//   }
// }