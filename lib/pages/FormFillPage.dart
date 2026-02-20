// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/theme/app_theme.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:um_collect/pages/GeometryMapPage.dart';
import 'package:um_collect/utils/form_logic.dart'
    show evaluateFieldVisibility, flattenFields, traverseFieldsVisible;

class FormFillPage extends StatefulWidget {
  final String formId;
  const FormFillPage({super.key, required this.formId});

  @override
  State<FormFillPage> createState() => _FormFillPageState();
}

class _FormFillPageState extends State<FormFillPage> {
  final storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? formData;
  Map<String, dynamic> responses = {};
  bool isLoading = true;
  bool isSubmitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchForm();
  }

  Future<void> fetchForm() async {
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

      final response = await http.get(
        Uri.parse("${getUrl()}forms/${widget.formId}"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          formData = data;
          isLoading = false;
          // Initialize responses with default values (support nested fields)
          if (data['fields'] != null) {
            final allFields = data['fields'] as List;
            final flat = flattenFields(allFields);
            for (var field in flat) {
              final name = field['name']?.toString();
              if (name == null) continue; // Containers have no name
              final fieldType = (field['type'] ?? '').toString().toLowerCase();
              if (fieldType == 'container') continue;
              if (field['defaultValue'] != null) {
                if (fieldType == 'multiselect') {
                  responses[name] = field['defaultValue'] is List
                      ? List.from(field['defaultValue'] as List)
                      : [field['defaultValue']];
                } else {
                  responses[name] = field['defaultValue'];
                }
              } else if (fieldType == 'multiselect') {
                responses[name] = [];
              } else if (fieldType == 'boolean') {
                responses[name] = null;
              }
              // Matrix: no default; leave unset
            }
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          error = 'Failed to load form. Please try again.';
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

  Future<void> submitForm() async {
    // Validate only visible leaf fields (supports nested containers)
    bool isValid = true;
    final fieldsTree = formData?['fields'] as List?;
    if (fieldsTree == null) {
      // no fields
    } else {
      final visibleFields = traverseFieldsVisible(fieldsTree, responses);
      for (var field in visibleFields) {
        final name = field['name']?.toString() ?? '';
        final required = field['required'] ?? false;
        final fieldType = (field['type'] ?? '').toString().toLowerCase();

        if (!required) continue;

        if (fieldType == 'multiselect') {
          final value = responses[name];
          if (value == null || (value is List && value.isEmpty)) {
            isValid = false;
            _showError('${field['label']} is required');
            break;
          }
        } else if (fieldType == 'boolean') {
          continue;
        } else if (fieldType == 'matrix') {
          final value = responses[name];
          if (value == null) {
            isValid = false;
            _showError('${field['label']} is required');
            break;
          }
        } else {
          final value = responses[name];
          if (value == null || value.toString().trim().isEmpty) {
            isValid = false;
            _showError('${field['label']} is required');
            break;
          }
        }
      }
    }

    if (!isValid) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final token = await storage.read(key: "mwstaffjwt");
      if (token == null) {
        _showError('Authentication required');
        return;
      }

      final response = await http
          .post(
            Uri.parse("${getUrl()}forms/${widget.formId}/submit"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'responses': responses,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Form submitted successfully!'),
                ],
              ),
              backgroundColor: AppTheme.successMain,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? 'Failed to submit form');
      }
    } catch (e) {
      _showError('Connection error. Please check your internet.');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.errorMain,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Clears values of fields that are currently hidden (supports nested containers).
  void _clearHiddenFieldValues() {
    final fieldsTree = formData?['fields'] as List?;
    if (fieldsTree == null) return;

    final visibleFields = traverseFieldsVisible(fieldsTree, responses);
    final visibleNames = <String>{};
    for (var f in visibleFields) {
      final name = f['name']?.toString();
      if (name != null) visibleNames.add(name);
    }

    final toRemove = responses.keys.where((k) => !visibleNames.contains(k)).toList();
    for (var name in toRemove) {
      responses.remove(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          formData?['name'] ?? 'Form',
          style: const TextStyle(
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
                        onPressed: fetchForm,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : formData == null
                  ? const Center(child: Text('Form not found'))
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.04,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (formData!['description'] != null &&
                                      formData!['description']
                                          .toString()
                                          .isNotEmpty) ...[
                                    Card(
                                      margin: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(context).size.height *
                                                0.02,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          MediaQuery.of(context).size.width *
                                              0.04,
                                        ),
                                        child: Text(
                                          formData!['description'],
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.035,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (formData!['fields'] != null)
                                    ...traverseFieldsVisible(
                                          formData!['fields'] as List,
                                          responses,
                                        ).map((field) => _buildField(field)),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.04,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.02,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isSubmitting ? null : submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryMain,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                              0.02,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.send),
                                            SizedBox(width: 8),
                                            Text(
                                              'Submit Form',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    final fieldType = (field['type'] ?? '').toLowerCase();
    final label = field['label'] ?? '';
    final name = field['name'] ?? '';
    final required = field['required'] ?? false;
    final hint = field['hint'] ?? '';

    switch (fieldType) {
      case 'text':
        return _buildTextField(field, label, name, required, hint);
      case 'textarea':
        return _buildTextAreaField(field, label, name, required, hint);
      case 'number':
      case 'integer':
      case 'decimal':
        return _buildNumberField(field, label, name, required, hint, fieldType);
      case 'date':
        return _buildDateField(field, label, name, required, hint);
      case 'datetime':
        return _buildDateTimeField(field, label, name, required, hint);
      case 'boolean':
        return _buildBooleanField(field, label, name, required);
      case 'select':
        return _buildSelectField(field, label, name, required, hint, false);
      case 'multiselect':
        return _buildSelectField(field, label, name, required, hint, true);
      case 'geometry':
        return _buildGeometryField(field, label, name, required, hint);
      case 'matrix':
        return _buildMatrixField(field, label, name, required, hint);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(Map<String, dynamic> field, String label, String name,
      bool required, String hint) {
    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: TextFormField(
          initialValue: responses[name]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
            hintText: hint.isNotEmpty ? hint : 'Enter $label',
            prefixIcon: const Icon(Icons.text_fields),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.015,
              horizontal: MediaQuery.of(context).size.width * 0.03,
            ),
          ),
          validator: (value) {
            // Only validate if field is visible
            final isVisible = evaluateFieldVisibility(
              field,
              responses,
              flattenFields(formData?['fields'] as List? ?? []),
            );
            if (!isVisible) return null; // Don't validate hidden fields
            
            if (required && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
          onSaved: (value) {
            responses[name] = value?.trim();
          },
          onChanged: (value) {
            setState(() {
              responses[name] = value.trim();
              _clearHiddenFieldValues();
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextAreaField(Map<String, dynamic> field, String label,
      String name, bool required, String hint) {
    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: TextFormField(
          initialValue: responses[name]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
            hintText: hint.isNotEmpty ? hint : 'Enter $label',
            prefixIcon: const Icon(Icons.notes),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.015,
              horizontal: MediaQuery.of(context).size.width * 0.03,
            ),
          ),
          maxLines: 4,
          validator: (value) {
            // Only validate if field is visible
            final isVisible = evaluateFieldVisibility(
              field,
              responses,
              flattenFields(formData?['fields'] as List? ?? []),
            );
            if (!isVisible) return null; // Don't validate hidden fields
            
            if (required && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
          onSaved: (value) {
            responses[name] = value?.trim();
          },
          onChanged: (value) {
            setState(() {
              responses[name] = value.trim();
              _clearHiddenFieldValues();
            });
          },
        ),
      ),
    );
  }

  Widget _buildNumberField(Map<String, dynamic> field, String label,
      String name, bool required, String hint, String type) {
    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: TextFormField(
          initialValue: responses[name]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
            hintText: hint.isNotEmpty ? hint : 'Enter $label',
            prefixIcon: const Icon(Icons.numbers),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.015,
              horizontal: MediaQuery.of(context).size.width * 0.03,
            ),
          ),
          keyboardType:
              TextInputType.numberWithOptions(decimal: type != 'integer'),
          validator: (value) {
            // Only validate if field is visible
            final isVisible = evaluateFieldVisibility(
              field,
              responses,
              flattenFields(formData?['fields'] as List? ?? []),
            );
            if (!isVisible) return null; // Don't validate hidden fields
            
            if (required) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              final num = type == 'integer'
                  ? int.tryParse(value)
                  : double.tryParse(value);
              if (num == null) {
                return 'Please enter a valid ${type == 'integer' ? 'integer' : 'number'}';
              }
              return null;
            } else {
              if (value != null && value.trim().isNotEmpty) {
                final num = type == 'integer'
                    ? int.tryParse(value)
                    : double.tryParse(value);
                if (num == null) {
                  return 'Please enter a valid ${type == 'integer' ? 'integer' : 'number'}';
                }
              }
              return null;
            }
          },
          onSaved: (value) {
            if (value != null && value.trim().isNotEmpty) {
              responses[name] =
                  type == 'integer' ? int.parse(value) : double.parse(value);
            }
          },
          onChanged: (value) {
            setState(() {
              if (value.trim().isNotEmpty) {
                final num = type == 'integer'
                    ? int.tryParse(value)
                    : double.tryParse(value);
                if (num != null) {
                  responses[name] = num;
                }
              }
              _clearHiddenFieldValues();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateField(Map<String, dynamic> field, String label, String name,
      bool required, String hint) {
    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: responses[name] != null
                  ? DateTime.parse(responses[name])
                  : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                responses[name] = date.toIso8601String().split('T')[0];
                _clearHiddenFieldValues();
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label + (required ? ' *' : ''),
              hintText: hint.isNotEmpty ? hint : 'Select $label',
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: responses[name] != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          responses.remove(name);
                          _clearHiddenFieldValues();
                        });
                      },
                    )
                  : null,
              errorText: required &&
                      evaluateFieldVisibility(
                        field,
                        responses,
                        flattenFields(formData?['fields'] as List? ?? []),
                      ) &&
                      (responses[name] == null ||
                          responses[name].toString().isEmpty)
                  ? 'This field is required'
                  : null,
            ),
            child: Text(
              responses[name] != null
                  ? DateFormat('yyyy-MM-dd')
                      .format(DateTime.parse(responses[name]))
                  : 'Select date',
              style: TextStyle(
                color: responses[name] != null
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(Map<String, dynamic> field, String label,
      String name, bool required, String hint) {
    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: responses[name] != null
                  ? DateTime.parse(responses[name])
                  : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  responses[name] != null
                      ? DateTime.parse(responses[name])
                      : DateTime.now(),
                ),
              );
              if (time != null) {
                final dateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                setState(() {
                  responses[name] = dateTime.toIso8601String();
                  _clearHiddenFieldValues();
                });
              }
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label + (required ? ' *' : ''),
              hintText: hint.isNotEmpty ? hint : 'Select date and time',
              prefixIcon: const Icon(Icons.access_time),
              suffixIcon: responses[name] != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          responses.remove(name);
                          _clearHiddenFieldValues();
                        });
                      },
                    )
                  : null,
              errorText: required &&
                      evaluateFieldVisibility(
                        field,
                        responses,
                        flattenFields(formData?['fields'] as List? ?? []),
                      ) &&
                      (responses[name] == null ||
                          responses[name].toString().isEmpty)
                  ? 'This field is required'
                  : null,
            ),
            child: Text(
              responses[name] != null
                  ? DateFormat('yyyy-MM-dd HH:mm')
                      .format(DateTime.parse(responses[name]))
                  : 'Select date and time',
              style: TextStyle(
                color: responses[name] != null
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBooleanField(
      Map<String, dynamic> field, String label, String name, bool required) {
    // Convert boolean response to "Yes"/"No" string for dropdown
    String? currentValue;
    if (responses[name] != null) {
      if (responses[name] == true ||
          responses[name] == 'true' ||
          responses[name] == 'Yes' ||
          responses[name] == 'yes' ||
          responses[name] == 1 ||
          responses[name] == '1') {
        currentValue = 'Yes';
      } else if (responses[name] == false ||
          responses[name] == 'false' ||
          responses[name] == 'No' ||
          responses[name] == 'no' ||
          responses[name] == 0 ||
          responses[name] == '0') {
        currentValue = 'No';
      }
    }

    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
            hintText: 'Select an option',
            prefixIcon: const Icon(Icons.check_circle_outline),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.015,
              horizontal: MediaQuery.of(context).size.width * 0.03,
            ),
          ),
          isExpanded: true,
          value: currentValue,
          items: const [
            DropdownMenuItem<String>(
              value: 'Yes',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Yes'),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'No',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('No'),
                ],
              ),
            ),
          ],
          validator: (value) {
            // Only validate if field is visible
            final isVisible = evaluateFieldVisibility(
              field,
              responses,
              flattenFields(formData?['fields'] as List? ?? []),
            );
            if (!isVisible) return null; // Don't validate hidden fields
            
            if (required && (value == null || value.isEmpty)) {
              return 'Please select an option';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              if (value == 'Yes') {
                responses[name] = true;
              } else if (value == 'No') {
                responses[name] = false;
              } else {
                responses.remove(name);
              }
              _clearHiddenFieldValues();
            });
          },
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.04,
            color: AppTheme.textPrimary,
          ),
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppTheme.primaryMain,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSelectField(Map<String, dynamic> field, String label,
      String name, bool required, String hint, bool isMulti) {
    final options = field['options'] ?? [];
    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: isMulti
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label + (required ? ' *' : ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (required &&
                      evaluateFieldVisibility(
                        field,
                        responses,
                        flattenFields(formData?['fields'] as List? ?? []),
                      ) &&
                      (responses[name] == null ||
                          (responses[name] is List &&
                              (responses[name] as List).isEmpty)))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'This field is required',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorMain,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: options.map<Widget>((option) {
                      final optionValue = option.toString();
                      final selected = (responses[name] as List?)
                              ?.any((item) => item.toString() == optionValue) ??
                          false;
                      return FilterChip(
                        label: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.02,
                          ),
                          child: Text(
                            optionValue,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.035,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        selected: selected,
                        onSelected: (selected) {
                          setState(() {
                            if (responses[name] == null) {
                              responses[name] = [];
                            }
                            final list = responses[name] as List;
                            if (selected) {
                              if (!list.any(
                                  (item) => item.toString() == optionValue)) {
                                list.add(optionValue);
                              }
                            } else {
                              list.removeWhere(
                                  (item) => item.toString() == optionValue);
                            }
                            _clearHiddenFieldValues();
                          });
                        },
                        selectedColor:
                            AppTheme.primaryMain.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryMain,
                        backgroundColor: Colors.grey[100],
                        side: BorderSide(
                          color: selected
                              ? AppTheme.primaryMain
                              : Colors.grey[300]!,
                          width: selected ? 2 : 1,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.03,
                          vertical: MediaQuery.of(context).size.height * 0.01,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              )
            : DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: label + (required ? ' *' : ''),
                  hintText: hint.isNotEmpty ? hint : 'Select $label',
                  prefixIcon: const Icon(Icons.list),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.015,
                    horizontal: MediaQuery.of(context).size.width * 0.03,
                  ),
                ),
                isExpanded: true,
                value: responses[name]?.toString(),
                items: options.map<DropdownMenuItem<String>>((option) {
                  final optionValue = option.toString();
                  return DropdownMenuItem<String>(
                    value: optionValue,
                    child: Text(
                      optionValue,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                validator: (value) {
                  // Only validate if field is visible
                  final isVisible = evaluateFieldVisibility(
                    field,
                    responses,
                    flattenFields(formData?['fields'] as List? ?? []),
                  );
                  if (!isVisible) return null; // Don't validate hidden fields
                  
                  if (required && (value == null || value.isEmpty)) {
                    return 'Please select an option';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    responses[name] = value;
                    _clearHiddenFieldValues();
                  });
                },
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: AppTheme.textPrimary,
                ),
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.primaryMain,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
      ),
    );
  }

  Widget _buildGeometryField(Map<String, dynamic> field, String label,
      String name, bool required, String hint) {
    final geometryType =
        (field['geometryType'] ?? 'POINT').toString().toUpperCase();
    final existingGeometry = responses[name];

    return Card(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label + (required ? ' *' : ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (existingGeometry != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        responses.remove(name);
                        _clearHiddenFieldValues();
                      });
                    },
                    tooltip: 'Clear selection',
                  ),
              ],
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    _GeometryMapWidget(
                      geometryType: geometryType,
                      initialGeometry: existingGeometry,
                      onGeometrySelected: (geometry) {
                        setState(() {
                          responses[name] = geometry;
                          _clearHiddenFieldValues();
                        });
                      },
                      isPreview: true,
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final result =
                                await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GeometryMapPage(
                                  geometryType: geometryType,
                                  initialGeometry:
                                      existingGeometry ?? responses[name],
                                  fieldLabel: label,
                                ),
                              ),
                            );
                            if (result != null && mounted) {
                              setState(() {
                                responses[name] = result;
                                _clearHiddenFieldValues();
                              });
                            } else if (result == null &&
                                mounted &&
                                existingGeometry == null) {
                              // User cancelled, clear if no initial geometry
                              setState(() {
                                responses.remove(name);
                                _clearHiddenFieldValues();
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.06,
                                  vertical: MediaQuery.of(context).size.height *
                                      0.015,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMain,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      existingGeometry != null
                                          ? Icons.edit_location
                                          : Icons.add_location,
                                      color: Colors.white,
                                      size: MediaQuery.of(context).size.width *
                                          0.05,
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Text(
                                      existingGeometry != null
                                          ? 'Edit Location'
                                          : 'Select Location',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            (MediaQuery.of(context).size.width *
                                                    0.038)
                                                .clamp(14.0, 16.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (required &&
                evaluateFieldVisibility(
                  field,
                  responses,
                  flattenFields(formData?['fields'] as List? ?? []),
                ) &&
                existingGeometry == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'This field is required',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorMain,
                  ),
                ),
              ),
            if (existingGeometry != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successMain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.successMain,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.successMain,
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
    );
  }

  Widget _buildMatrixField(Map<String, dynamic> field, String label,
      String name, bool required, String hint) {
    final rows = (field['rows'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final columns = (field['columns'] as List?)?.map((e) => e.toString()).toList() ?? [];

    // responses[name] is Map<String, Map<String, String>>: row -> (col -> value)
    Map<String, dynamic> current = const {};
    try {
      final r = responses[name];
      if (r is Map) {
        current = Map<String, dynamic>.from(r);
      } else if (r is String && r.trim().isNotEmpty) {
        current = Map<String, dynamic>.from(jsonDecode(r) as Map);
      }
    } catch (_) {}

    return Card(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label + (required ? ' *' : ''),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            if (rows.isEmpty || columns.isEmpty)
              Text(
                'No rows or columns defined',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            else
              ...rows.map((row) {
                final rowMap = (current[row] is Map)
                    ? Map<String, String>.from(current[row] as Map)
                    : <String, String>{};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: columns.map((col) {
                          final key = col;
                          final value = rowMap[key] ?? '';
                          return SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: value,
                              decoration: InputDecoration(
                                labelText: col,
                                isDense: true,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  final r = responses[name];
                                  Map<String, dynamic> copy = r is Map
                                      ? Map<String, dynamic>.from(r)
                                      : {};
                                  if (copy[row] is! Map) copy[row] = <String, String>{};
                                  (copy[row] as Map)[key] = v;
                                  responses[name] = copy;
                                  _clearHiddenFieldValues();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            if (required &&
                evaluateFieldVisibility(
                  field,
                  responses,
                  flattenFields(formData?['fields'] as List? ?? []),
                ) &&
                (responses[name] == null ||
                    (responses[name] is Map &&
                        (responses[name] as Map).isEmpty)))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'This field is required',
                  style: TextStyle(fontSize: 12, color: AppTheme.errorMain),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GeometryMapWidget extends StatefulWidget {
  final String geometryType;
  final dynamic initialGeometry;
  final Function(Map<String, dynamic>) onGeometrySelected;
  final bool isPreview;

  const _GeometryMapWidget({
    required this.geometryType,
    this.initialGeometry,
    required this.onGeometrySelected,
    this.isPreview = false,
  });

  @override
  State<_GeometryMapWidget> createState() => _GeometryMapWidgetState();
}

class _GeometryMapWidgetState extends State<_GeometryMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  LatLng _currentLocation = const LatLng(-1.2940491, 36.8076449);
  List<LatLng> _selectedPoints = [];
  bool _isLoading = true;
  bool _isGettingGps = false;
  bool _isTracking = false;
  Timer? _trackingTimer;
  double _totalDistance = 0.0; // Distance in meters

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadInitialGeometry();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  void _startTracking() async {
    if (_isTracking || widget.geometryType == 'POINT') return;

    // Request permission first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return;
    }

    // Get initial position
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final initialPoint =
          LatLng(initialPosition.latitude, initialPosition.longitude);

      setState(() {
        _isTracking = true;
        _currentLocation = initialPoint;
        if (_selectedPoints.isEmpty) {
          _selectedPoints = [initialPoint];
          _updateMarkers();
        } else {
          // Calculate distance from last point
          final lastPoint = _selectedPoints.last;
          final distance = _calculateDistance(lastPoint, initialPoint);
          _totalDistance += distance;

          _selectedPoints.add(initialPoint);
          _updateMarkers();
          _updatePolylines();
          _updatePolygons();
        }
        _createGeometry();
      });
      _updateCamera();

      // Start timer to update every minute
      _trackingTimer =
          Timer.periodic(const Duration(minutes: 1), (timer) async {
        if (!mounted || !_isTracking) {
          timer.cancel();
          return;
        }

        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          if (!mounted || !_isTracking) return;

          final point = LatLng(position.latitude, position.longitude);
          final lastPoint =
              _selectedPoints.isNotEmpty ? _selectedPoints.last : point;

          // Calculate distance moved
          final distance = _calculateDistance(lastPoint, point);

          // Only add point if moved at least 5 meters (to avoid duplicate points)
          if (distance >= 5.0) {
            setState(() {
              _totalDistance += distance;
              _currentLocation = point;
              _selectedPoints.add(point);
              _updateMarkers();
              _updatePolylines();
              _updatePolygons();
              _createGeometry();
            });
            _updateCamera();
          }
        } catch (e) {
          // Error getting location, continue tracking
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isTracking = false);
      }
    }
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  Future<void> _getAndApplyGpsLocation() async {
    if (_isGettingGps || !mounted) return;
    setState(() => _isGettingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isGettingGps = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isGettingGps = false);
          return;
        }
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) setState(() => _isGettingGps = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = point;
        if (widget.geometryType == 'POINT') {
          _selectedPoints = [point];
          _updateMarkers();
        } else {
          _selectedPoints.add(point);
          _updateMarkers();
          _updatePolylines();
          _updatePolygons();
        }
        _createGeometry();
        _isGettingGps = false;
      });
      _updateCamera();
    } catch (e) {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _updateCamera();
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadInitialGeometry() {
    if (widget.initialGeometry != null) {
      try {
        Map<String, dynamic> geometry = widget.initialGeometry is String
            ? jsonDecode(widget.initialGeometry)
            : widget.initialGeometry;

        String type = geometry['type']?.toString().toUpperCase() ?? 'POINT';
        List coordinates = geometry['coordinates'] ?? [];

        if (type == 'POINT' && coordinates.length >= 2) {
          LatLng point = LatLng(
            coordinates[1].toDouble(),
            coordinates[0].toDouble(),
          );
          _selectedPoints = [point];
          _updateMarkers();
          _currentLocation = point;
        } else if (type == 'LINESTRING' && coordinates.isNotEmpty) {
          _selectedPoints = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          _updateMarkers();
          _updatePolylines();
          if (_selectedPoints.isNotEmpty) {
            _currentLocation = _selectedPoints.first;
          }
        } else if (type == 'POLYGON' && coordinates.isNotEmpty) {
          List ring = coordinates[0];
          _selectedPoints = ring.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          _updateMarkers();
          _updatePolygons();
          if (_selectedPoints.isNotEmpty) {
            _currentLocation = _selectedPoints.first;
          }
        }
      } catch (e) {
        // Error parsing initial geometry
      }
    }
  }

  void _updateCamera() async {
    try {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation,
            zoom: _selectedPoints.isEmpty ? 15.0 : 18.0,
          ),
        ),
      );
    } catch (e) {
      // Error updating camera
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      if (widget.geometryType == 'POINT') {
        _selectedPoints = [position];
        _updateMarkers();
        _createGeometry();
      } else if (widget.geometryType == 'LINESTRING') {
        _selectedPoints.add(position);
        _updateMarkers();
        _updatePolylines();
        _createGeometry();
      } else if (widget.geometryType == 'POLYGON') {
        _selectedPoints.add(position);
        _updateMarkers();
        _updatePolygons();
        _createGeometry();
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();
    for (int i = 0; i < _selectedPoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: _selectedPoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.geometryType == 'POINT'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();
    if (_selectedPoints.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('line'),
          points: _selectedPoints,
          color: AppTheme.primaryMain,
          width: 3,
        ),
      );
    }
  }

  void _updatePolygons() {
    _polygons.clear();
    if (_selectedPoints.length >= 3) {
      // Close the polygon by adding the first point at the end
      List<LatLng> closedPoints = List.from(_selectedPoints);
      closedPoints.add(_selectedPoints.first);

      _polygons.add(
        Polygon(
          polygonId: const PolygonId('polygon'),
          points: _selectedPoints,
          strokeColor: AppTheme.primaryMain,
          fillColor: AppTheme.primaryMain.withValues(alpha: 0.2),
          strokeWidth: 3,
        ),
      );
    }
  }

  void _createGeometry() {
    if (_selectedPoints.isEmpty) {
      widget.onGeometrySelected({});
      return;
    }

    Map<String, dynamic> geometry;

    if (widget.geometryType == 'POINT') {
      geometry = {
        'type': 'Point',
        'coordinates': [
          _selectedPoints[0].longitude,
          _selectedPoints[0].latitude,
        ],
      };
    } else if (widget.geometryType == 'LINESTRING') {
      geometry = {
        'type': 'LineString',
        'coordinates': _selectedPoints.map((point) {
          return [point.longitude, point.latitude];
        }).toList(),
      };
    } else if (widget.geometryType == 'POLYGON') {
      // Close the polygon
      List<List<double>> coordinates = _selectedPoints.map((point) {
        return [point.longitude, point.latitude];
      }).toList();
      coordinates
          .add([_selectedPoints[0].longitude, _selectedPoints[0].latitude]);

      geometry = {
        'type': 'Polygon',
        'coordinates': [coordinates],
      };
    } else {
      return;
    }

    widget.onGeometrySelected(geometry);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation,
            zoom: 15,
          ),
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          markers: _markers,
          polylines: _polylines,
          polygons: _polygons,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            if (_selectedPoints.isNotEmpty) {
              _updateCamera();
            }
          },
          onTap: widget.isPreview ? null : _onMapTap,
        ),
        if (_isLoading)
          Container(
            color: Colors.white.withValues(alpha: 0.8),
            child: Center(
              child: LoadingAnimationWidget.horizontalRotatingDots(
                color: AppTheme.primaryMain,
                size: 50,
              ),
            ),
          ),
        if (!widget.isPreview)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.045,
                  vertical: MediaQuery.of(context).size.height * 0.018,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.geometryType == 'POINT'
                              ? Icons.location_on
                              : widget.geometryType == 'LINESTRING'
                                  ? Icons.timeline
                                  : Icons.map,
                          color: AppTheme.primaryMain,
                          size: MediaQuery.of(context).size.width * 0.07,
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.03),
                        Expanded(
                          child: Text(
                            widget.geometryType == 'POINT'
                                ? 'Tap map or use GPS'
                                : 'Tap map or add GPS (${_selectedPoints.length})',
                            style: TextStyle(
                              fontSize:
                                  (MediaQuery.of(context).size.width * 0.042)
                                      .clamp(14.0, 18.0),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (_selectedPoints.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: MediaQuery.of(context).size.width * 0.065,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedPoints.clear();
                                _markers.clear();
                                _polylines.clear();
                                _polygons.clear();
                                widget.onGeometrySelected({});
                              });
                            },
                            tooltip: 'Clear all',
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.02),
                          ),
                      ],
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015),
                    if (_isTracking && widget.geometryType != 'POINT')
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.012,
                          horizontal: MediaQuery.of(context).size.width * 0.035,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successMain.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.successMain.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: MediaQuery.of(context).size.width * 0.055,
                              color: AppTheme.successMain,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
                            Expanded(
                              child: Text(
                                'Tracking: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
                                style: TextStyle(
                                  fontSize: (MediaQuery.of(context).size.width *
                                          0.038)
                                      .clamp(13.0, 16.0),
                                  color: AppTheme.successMain,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isTracking && widget.geometryType != 'POINT')
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.012),
                    Row(
                      children: [
                        if (widget.geometryType != 'POINT')
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _isTracking ? _stopTracking : _startTracking,
                              icon: _isTracking
                                  ? Icon(
                                      Icons.stop_circle,
                                      size: MediaQuery.of(context).size.width *
                                          0.055,
                                    )
                                  : Icon(
                                      Icons.gps_fixed,
                                      size: MediaQuery.of(context).size.width *
                                          0.055,
                                    ),
                              label: Text(
                                _isTracking
                                    ? 'Stop tracking'
                                    : 'Start GPS tracking',
                                style: TextStyle(
                                  fontSize: (MediaQuery.of(context).size.width *
                                          0.038)
                                      .clamp(13.0, 16.0),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _isTracking
                                    ? AppTheme.errorMain
                                    : AppTheme.successMain,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: MediaQuery.of(context).size.height *
                                      0.016,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (widget.geometryType != 'POINT')
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isGettingGps || _isTracking
                                ? null
                                : _getAndApplyGpsLocation,
                            icon: _isGettingGps
                                ? SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.055,
                                    height: MediaQuery.of(context).size.width *
                                        0.055,
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  )
                                : Icon(
                                    Icons.gps_fixed,
                                    size: MediaQuery.of(context).size.width *
                                        0.055,
                                  ),
                            label: Text(
                              _isGettingGps
                                  ? 'Getting location…'
                                  : 'Add GPS point',
                              style: TextStyle(
                                fontSize:
                                    (MediaQuery.of(context).size.width * 0.038)
                                        .clamp(13.0, 16.0),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryMain,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.height * 0.016,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
