import 'package:cropCompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class DocumentFormBuilder extends StatefulWidget {
  final DocumentTypeModel documentType;
  final Map<String, dynamic>? formConfig;
  final Function(String, dynamic) onFormDataChanged;

  const DocumentFormBuilder({
    Key? key,
    required this.documentType,
    this.formConfig,
    required this.onFormDataChanged,
  }) : super(key: key);

  @override
  State<DocumentFormBuilder> createState() => _DocumentFormBuilderState();
}

class _DocumentFormBuilderState extends State<DocumentFormBuilder> {
  @override
  void initState() {
    super.initState();
    print("DocumentFormBuilder - Form config received: ${widget.formConfig != null ? 'Yes' : 'No'}");
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have a valid form config
    if (widget.formConfig != null && widget.formConfig!.containsKey('configJson')) {
      print("Using custom form config for ${widget.documentType.name}");
      return _buildDynamicForm(widget.formConfig!);
    }

    // If no valid form config, use default implementation
    print("Using default form for ${widget.documentType.name}");
    return _buildFormForDocumentType(widget.documentType.id);
  }

  Widget _buildDynamicForm(Map<String, dynamic> formConfig) {
    print("Building dynamic form with config keys: ${formConfig.keys.toList()}");
    try {
      // Extract the fields from configJson
      final configJson = formConfig['configJson'];
      print("configJson type: ${configJson.runtimeType}");

      if (configJson is Map && configJson.containsKey('fields')) {
        print("Found fields array with ${(configJson['fields'] as List).length} items");
        final fields = configJson['fields'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: fields.map<Widget>((field) {
            // Extract field properties
            final String label = field['label'] ?? context.l10n.formUntitledField;
            final String type = field['type'] ?? 'text';
            final String fieldKey = field['key'] ?? label.toLowerCase().replaceAll(' ', '_');

            print("Building field: $label (type: $type, key: $fieldKey)");

            // Build the appropriate field widget based on type
            switch (type) {
              case 'text':
                return _buildTextField(
                    fieldKey,
                    label,
                    field['placeholder'] ?? context.l10n.formEnterField(label)
                );
              case 'textarea':
                return _buildMultilineTextField(
                    fieldKey,
                    label,
                    field['placeholder'] ?? context.l10n.formEnterField(label)
                );
              case 'date':
                return _buildDateField(fieldKey, label);
              case 'dropdown':
                if (field.containsKey('options') && field['options'] is List) {
                  final options = (field['options'] as List)
                      .map((o) => o.toString())
                      .toList();
                  return _buildDropdownField(fieldKey, label, options);
                }
                return _buildTextField(fieldKey, label, context.l10n.formNoOptions);
              case 'checkbox':
                return _buildCheckboxField(fieldKey, label);
              default:
                return _buildTextField(fieldKey, label, context.l10n.formEnterField(label));
            }
          }).toList(),
        );
      }

      // If configJson doesn't have fields, return a message
      print("Invalid form configuration: ${configJson is Map ? 'Missing fields key' : 'configJson is not a Map'}");
      return Center(
        child: Text(context.l10n.formInvalidConfig),
      );
    } catch (e) {
      // If any error occurs, log it and return a message
      print('Error building dynamic form: $e');
      return Center(
        child: Text(context.l10n.formBuildError('$e')),
      );
    }
  }

  Widget _buildFormForDocumentType(String documentTypeId) {
    // This is a simplified implementation just for demonstration
    // In a real app, you would have more sophisticated form generation logic

    // Generate different forms based on document type ID patterns
    // These examples are just placeholders
    if (documentTypeId.contains('contract')) {
      return _buildContractForm();
    } else if (documentTypeId.contains('certification')) {
      return _buildCertificationForm();
    } else if (documentTypeId.contains('inspection')) {
      return _buildInspectionForm();
    } else if (documentTypeId.contains('risk')) {
      return _buildRiskAssessmentForm();
    } else {
      return _buildGenericForm();
    }
  }

  Widget _buildContractForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'contractName',
          context.l10n.formContractName,
          context.l10n.formContractNameHint,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'contractNumber',
          context.l10n.formContractNumber,
          context.l10n.formContractNumberHint,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'counterparty',
          context.l10n.formCounterparty,
          context.l10n.formCounterpartyHint,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'effectiveDate',
          context.l10n.formEffectiveDate,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'status',
          context.l10n.formContractStatus,
          ['Active', 'Pending', 'Terminated', 'Expired'], // l10n-ignore: stored values
          display: {
            'Active': context.l10n.formOptActive, // l10n-ignore: stored value
            'Pending': context.l10n.formOptPending, // l10n-ignore: stored value
            'Terminated': context.l10n.formOptTerminated, // l10n-ignore: stored value
            'Expired': context.l10n.formOptExpired, // l10n-ignore: stored value
          },
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'description',
          context.l10n.fieldDescription,
          context.l10n.formContractDescHint,
        ),
      ],
    );
  }

  Widget _buildCertificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'certificationName',
          context.l10n.formCertName,
          context.l10n.formCertNameHint,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'certificationNumber',
          context.l10n.formCertNumber,
          context.l10n.formCertNumberHint,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'issuingAuthority',
          context.l10n.formIssuingAuthority,
          context.l10n.formIssuingAuthorityHint,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'issueDate',
          context.l10n.formIssueDate,
        ),
        const SizedBox(height: 16),
        _buildCheckboxField(
          'hasRestrictions',
          context.l10n.formHasRestrictions,
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'notes',
          context.l10n.formNotes,
          context.l10n.formNotesHint,
        ),
      ],
    );
  }

  Widget _buildInspectionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'inspectionLocation',
          context.l10n.formInspectionLocation,
          context.l10n.formInspectionLocationHint,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'inspectionDate',
          context.l10n.formInspectionDate,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'inspector',
          context.l10n.formInspector,
          context.l10n.formInspectorHint,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'result',
          context.l10n.formInspectionResult,
          ['Pass', 'Pass with Conditions', 'Fail', 'Incomplete'], // l10n-ignore: stored values
          display: {
            'Pass': context.l10n.formOptPass, // l10n-ignore: stored value
            'Pass with Conditions': context.l10n.formOptPassConditions, // l10n-ignore: stored value
            'Fail': context.l10n.formOptFail, // l10n-ignore: stored value
            'Incomplete': context.l10n.formOptIncomplete, // l10n-ignore: stored value
          },
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'findings',
          context.l10n.formFindings,
          context.l10n.formFindingsHint,
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'recommendations',
          context.l10n.formRecommendations,
          context.l10n.formRecommendationsHint,
        ),
      ],
    );
  }

  Widget _buildRiskAssessmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'assessmentTitle',
          context.l10n.formAssessmentTitle,
          context.l10n.formAssessmentTitleHint,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'assessmentDate',
          context.l10n.formAssessmentDate,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'assessor',
          context.l10n.formAssessor,
          context.l10n.formAssessorHint,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'riskLevel',
          context.l10n.formOverallRisk,
          ['Low', 'Medium', 'High', 'Critical'], // l10n-ignore: stored values
          display: {
            'Low': context.l10n.formOptLow, // l10n-ignore: stored value
            'Medium': context.l10n.formOptMedium, // l10n-ignore: stored value
            'High': context.l10n.formOptHigh, // l10n-ignore: stored value
            'Critical': context.l10n.formOptCritical, // l10n-ignore: stored value
          },
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'hazards',
          context.l10n.formHazards,
          context.l10n.formHazardsHint,
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'controls',
          context.l10n.formControlMeasures,
          context.l10n.formControlMeasuresHint,
        ),
        const SizedBox(height: 16),
        _buildCheckboxField(
          'requiresFollowUp',
          context.l10n.formRequiresFollowUp,
        ),
      ],
    );
  }

  Widget _buildGenericForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'title',
          context.l10n.formTitle,
          context.l10n.formTitleHint,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'reference',
          context.l10n.reference,
          context.l10n.formReferenceHint,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'documentDate',
          context.l10n.formDocumentDate,
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'notes',
          context.l10n.formNotes,
          context.l10n.formNotesHint,
        ),
      ],
    );
  }

  Widget _buildTextField(
      String fieldKey,
      String label,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.onFormDataChanged(fieldKey, value);
          },
        ),
      ],
    );
  }

  Widget _buildMultilineTextField(
      String fieldKey,
      String label,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) {
            widget.onFormDataChanged(fieldKey, value);
          },
        ),
      ],
    );
  }

  Widget _buildDateField(
      String fieldKey,
      String label,
      ) {
    DateTime? selectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            if (date != null) {
              setState(() {
                selectedDate = date;
              });
              widget.onFormDataChanged(fieldKey, date.toIso8601String());
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : context.l10n.formSelectDate,
                  ),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// [options] are the values stored on the document; [display] (optional)
  /// shows them in the app language.
  Widget _buildDropdownField(
      String fieldKey,
      String label,
      List<String> options, {
      Map<String, String>? display,
      }) {
    String? selectedValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          value: selectedValue,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(display?[option] ?? option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedValue = value;
            });
            if (value != null) {
              widget.onFormDataChanged(fieldKey, value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCheckboxField(
      String fieldKey,
      String label,
      ) {
    bool isChecked = false;

    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (value) {
            setState(() {
              isChecked = value ?? false;
            });
            widget.onFormDataChanged(fieldKey, isChecked);
          },
        ),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}