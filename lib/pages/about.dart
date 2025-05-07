import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Our App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Our app is dedicated to crowd-sourcing spatial data related to water utilities. It empowers the public to report various incidents concerning water utilities infrastructure, contributing to the improvement of water management and conservation efforts.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Key Features:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '- Report Incidents: Users can report incidents such as leakages, sewer bursts, supply failures, illegal connections, vandalism, and others directly through the app.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            Text(
              '- Geo-tagging: The app utilizes spatial data to accurately pinpoint the location of reported incidents, facilitating efficient response and resolution.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            Text(
              '- Community Engagement: By engaging the public in the monitoring and reporting of water utility issues, our app fosters a sense of community involvement and responsibility towards water resource management.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Our Mission:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Our mission is to promote transparency, accountability, and sustainability in water management through technology-driven solutions. By harnessing the collective power of citizen participation, we aim to address water-related challenges and create a more resilient and equitable water infrastructure.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Contact Us:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'For any inquiries or feedback regarding our app, please contact us at [contact email/phone number]. We welcome your input and suggestions for improvement.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
