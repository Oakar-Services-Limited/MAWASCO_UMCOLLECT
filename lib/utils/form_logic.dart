/// Utility for evaluating field visibility based on conditional logic.
/// This mirrors the backend evaluateFieldLogic function for client-side rendering.

/// Evaluates whether a field should be visible based on conditional logic.
/// Returns true if field should be visible, false if hidden.
bool evaluateFieldVisibility(
  Map<String, dynamic> field,
  Map<String, dynamic> responses,
  List<dynamic> allFields,
) {
  // If no logic defined, field is always visible
  final logic = field['logic'];
  if (logic == null || logic is! Map) {
    return true;
  }

  final dependsOn = logic['dependsOn']?.toString().trim();
  final showIfAnswer = logic['showIfAnswer']?.toString().trim();

  // If logic is incomplete, show field (fail-safe)
  if (dependsOn == null ||
      dependsOn.isEmpty ||
      showIfAnswer == null ||
      showIfAnswer.isEmpty) {
    return true;
  }

  // Find the controlling field by name, id, or label
  Map<String, dynamic>? controllingField;
  for (var f in allFields) {
    if (f is Map<String, dynamic>) {
      final fName = f['name']?.toString();
      final fId = f['id']?.toString();
      final fLabel = f['label']?.toString();
      if (fName == dependsOn ||
          fId == dependsOn ||
          fLabel == dependsOn) {
        controllingField = f;
        break;
      }
    }
  }

  // If controlling field doesn't exist, show field (fail-safe)
  if (controllingField == null) {
    return true;
  }

  // Get the response value for the controlling field
  final controllingFieldName = controllingField['name']?.toString();
  final controllingFieldId = controllingField['id']?.toString();
  final controllingFieldLabel = controllingField['label']?.toString();

  dynamic controllingResponse = responses[controllingFieldName] ??
      responses[controllingFieldId] ??
      responses[controllingFieldLabel];

  // Handle null/empty responses
  if (controllingResponse == null ||
      controllingResponse.toString().trim().isEmpty) {
    return false; // Hidden if controlling field has no answer
  }

  // Normalize showIfAnswer for comparison
  final normalizedShowIfAnswer = showIfAnswer.toLowerCase();

  // Handle different field types
  final controllingType = (controllingField['type'] ?? '').toString().toLowerCase();

  if (controllingType == 'boolean') {
    // For boolean fields, compare boolean values
    // Handle both boolean and string representations (Yes/No, true/false, etc.)
    final responseBool = controllingResponse == true ||
        controllingResponse == 'true' ||
        controllingResponse == 1 ||
        controllingResponse == '1' ||
        controllingResponse.toString().toLowerCase() == 'yes';
    
    // Normalize showIfAnswer - handle "Yes", "No", "true", "false", etc.
    final showIfLower = normalizedShowIfAnswer.toLowerCase();
    final showIfBool = showIfLower == 'true' ||
        showIfLower == '1' ||
        showIfLower == 'yes';
    
    return responseBool == showIfBool;
  }

  if (controllingType == 'multiselect') {
    // For multiselect, check if showIfAnswer is in the array
    List<dynamic> responseArray;
    if (controllingResponse is List) {
      responseArray = controllingResponse;
    } else if (controllingResponse is String) {
      responseArray = controllingResponse
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      responseArray = [controllingResponse];
    }
    return responseArray.any((val) =>
        val.toString().trim().toLowerCase() == normalizedShowIfAnswer);
  }

  if (controllingType == 'select') {
    // For select, exact match (case-insensitive)
    return controllingResponse
            .toString()
            .trim()
            .toLowerCase() ==
        normalizedShowIfAnswer;
  }

  // Fallback: string comparison (case-insensitive)
  return controllingResponse.toString().trim().toLowerCase() ==
      normalizedShowIfAnswer;
}

/// Computes visibility for all fields in a form based on current responses.
/// Returns a map of field names to visibility boolean.
Map<String, bool> computeFieldVisibility(
  List<dynamic> fields,
  Map<String, dynamic> responses,
) {
  final flat = flattenFields(fields);
  final visibilityMap = <String, bool>{};

  for (var field in flat) {
    final isVisible = evaluateFieldVisibility(field, responses, flat);
    final name = field['name']?.toString();
    final id = field['id']?.toString();
    final label = field['label']?.toString();

    if (name != null) visibilityMap[name] = isVisible;
    if (id != null) visibilityMap[id] = isVisible;
    if (label != null) visibilityMap[label] = isVisible;
  }

  return visibilityMap;
}

/// Flattens a tree of fields (containers with children) into a single list, depth-first.
/// Use this to get "all fields" for visibility evaluation when the form has nested sections.
List<Map<String, dynamic>> flattenFields(List<dynamic> fields) {
  final out = <Map<String, dynamic>>[];
  if (fields.isEmpty) return out;

  for (var raw in fields) {
    if (raw is! Map<String, dynamic>) continue;
    out.add(raw);

    final type = (raw['type'] ?? '').toString().toLowerCase();
    final children = raw['children'];
    if (type == 'container' && children is List && children.isNotEmpty) {
      out.addAll(flattenFields(children));
    }
  }
  return out;
}

/// Returns a flat list of visible leaf/matrix fields only (no containers).
/// If a container is hidden, all its children are excluded.
/// Use this to decide which fields to render and to validate on submit.
List<Map<String, dynamic>> traverseFieldsVisible(
  List<dynamic> fields,
  Map<String, dynamic> responses, [
  List<Map<String, dynamic>>? allFieldsFlat,
]) {
  final flat = allFieldsFlat ?? flattenFields(fields);
  final out = <Map<String, dynamic>>[];

  void visit(List<dynamic> fieldList) {
    for (var raw in fieldList) {
      if (raw is! Map<String, dynamic>) continue;

      final isVisible = evaluateFieldVisibility(raw, responses, flat);
      if (!isVisible) continue;

      final type = (raw['type'] ?? '').toString().toLowerCase();
      if (type == 'container') {
        final children = raw['children'];
        if (children is List && children.isNotEmpty) {
          visit(children);
        }
        continue;
      }

      out.add(raw);
    }
  }

  visit(fields);
  return out;
}
