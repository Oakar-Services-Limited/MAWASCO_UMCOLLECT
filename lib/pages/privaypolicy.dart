// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/pages/home.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  void _launchURL() async {
    const url = 'https://osl.co.ke/contact-us/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const Home()));
            },
          ),
        ],
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MyDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Our app is committed to ensuring the privacy and security of your personal data. This Privacy Policy explains how we collect, use, and protect your information when you use our app.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Information We Collect',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. Personal Details: We may collect personal details such as your name, phone number, ID number, and email address for account registration and authentication purposes.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Text(
              '2. Location Information: Our app may collect and store your location information to provide location-based services, such as mapping features. You can control the app\'s access to your location through your device settings.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Text(
              '3. Camera Usage: We may request access to your device\'s camera for features such as capturing images or scanning QR codes. We do not store images captured by the camera unless explicitly permitted by you.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Text(
              '4. Access to System Files and Documents: Our app may require access to system files and documents on your device to perform specific functions, such as importing or exporting data. We ensure that this access is limited to what is necessary for the app\'s functionality and does not compromise your data security.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Data Security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We implement appropriate technical and organizational measures to safeguard your personal data against unauthorized access, alteration, disclosure, or destruction. Your data is stored securely and accessed only by authorized personnel.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Changes to This Privacy Policy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We reserve the right to update or modify this Privacy Policy at any time. Any changes will be effective immediately upon posting the updated Privacy Policy on this page. We encourage you to review this Privacy Policy periodically for any updates.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'MAWASCO Data Ownership and Consent',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'By using our services, you acknowledge and consent that:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. All customer data collected through this application belongs to MAWASCO and is subject to MAWASCO\'s regulations and policies.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Text(
              '2. Your data will be stored and processed by MAWASCO for operational purposes and in accordance with MAWASCO\'s regulations.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Text(
              '3. Due to operational requirements and regulatory compliance, customer data cannot be deleted from MAWASCO\'s systems.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Text(
              '4. For any queries regarding your data, you may contact MAWASCO through the contact number provided in the Play Store listing or by directly reaching out to MAWASCO\'s customer service.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                text:
                    'If you have any questions or concerns about our Privacy Policy or the handling of your personal data, please contact us at ',
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(
                    text: 'https://osl.co.ke/contact-us/',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url = 'https://osl.co.ke/contact-us/';
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                  ),
                  const TextSpan(
                    text: '.',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
