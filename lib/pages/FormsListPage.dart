// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/theme/app_theme.dart';
import 'package:um_collect/pages/FormFillPage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class FormsListPage extends StatefulWidget {
  const FormsListPage({super.key});

  @override
  State<FormsListPage> createState() => _FormsListPageState();
}

class _FormsListPageState extends State<FormsListPage> {
  final storage = const FlutterSecureStorage();
  List<dynamic> forms = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchForms();
  }

  Future<void> fetchForms() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await storage.read(key: "mwstaffjwt");
      if (token == null) {
        if (!mounted) return;
        setState(() {
          error = 'Authentication required';
          isLoading = false;
        });
        return;
      }

      print('[FORMS DEBUG] Fetching forms from: ${getUrl()}forms');
      final response = await http.get(
        Uri.parse("${getUrl()}forms"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('[FORMS DEBUG] Response status: ${response.statusCode}');
      print('[FORMS DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('[FORMS DEBUG] Parsed data type: ${data.runtimeType}');
          print('[FORMS DEBUG] Data is List: ${data is List}');
          if (!mounted) return;
          setState(() {
            forms = data is List ? data : [];
            isLoading = false;
            error = null;
          });
        } catch (e) {
          print('[FORMS DEBUG] JSON parse error: $e');
          if (!mounted) return;
          setState(() {
            error = 'Invalid response from server. Please try again.';
            isLoading = false;
          });
        }
      } else {
        String errorMessage = 'Failed to load forms. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          print('[FORMS DEBUG] Error parsing error response: $e');
          // If JSON parsing fails, use default message
        }
        print('[FORMS DEBUG] Setting error: $errorMessage');
        if (!mounted) return;
        setState(() {
          error = errorMessage;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Connection error. Please check your internet.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Forms",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryMain,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.horizontalRotatingDots(
                color: AppTheme.primaryMain,
                size: 100,
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorMain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: fetchForms,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMain,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : forms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No forms available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check back later for new forms',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchForms,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: forms.length,
                        itemBuilder: (context, index) {
                          final form = forms[index];
                          return _buildFormCard(form);
                        },
                      ),
                    ),
    );
  }

  Widget _buildFormCard(Map<String, dynamic> form) {
    final status = form['status'] ?? 'draft';
    final submissionCount = form['submissionCount'] ?? 0;
    final isPublished = status == 'published';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isPublished
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormFillPage(formId: form['id']),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPublished
                  ? AppTheme.primaryMain.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form['name'] ?? 'Untitled Form',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPublished
                                ? AppTheme.primaryMain
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (form['description'] != null &&
                            form['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            form['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? AppTheme.successMain.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPublished
                            ? AppTheme.successMain
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${form['fields']?.length ?? 0} fields',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.assignment_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$submissionCount submissions',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (!isPublished) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.warningMain,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This form is not available for submission',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.warningMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
