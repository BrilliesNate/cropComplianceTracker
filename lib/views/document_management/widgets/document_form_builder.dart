import 'package:cropCompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';

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
            final String label = field['label'] ?? 'Untitled Field';
            final String type = field['type'] ?? 'text';
            final String fieldKey = field['key'] ?? label.toLowerCase().replaceAll(' ', '_');

            print("Building field: $label (type: $type, key: $fieldKey)");

            // Build the appropriate field widget based on type
            switch (type) {
              case 'text':
                return _buildTextField(
                    fieldKey,
                    label,
                    field['placeholder'] ?? 'Enter $label'
                );
              case 'textarea':
                return _buildMultilineTextField(
                    fieldKey,
                    label,
                    field['placeholder'] ?? 'Enter $label'
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
                return _buildTextField(fieldKey, label, 'No options provided');
              case 'checkbox':
                return _buildCheckboxField(fieldKey, label);
              default:
                return _buildTextField(fieldKey, label, 'Enter $label');
            }
          }).toList(),
        );
      }

      // If configJson doesn't have fields, return a message
      print("Invalid form configuration: ${configJson is Map ? 'Missing fields key' : 'configJson is not a Map'}");
      return const Center(
        child: Text('Invalid form configuration: missing fields'),
      );
    } catch (e) {
      // If any error occurs, log it and return a message
      print('Error building dynamic form: $e');
      return Center(
        child: Text('Error building form: $e'),
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
          'Contract Name',
          'Enter the name of the contract',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'contractNumber',
          'Contract Number',
          'Enter the contract reference number',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'counterparty',
          'Counterparty',
          'Enter the name of the other party',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'effectiveDate',
          'Effective Date',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'status',
          'Contract Status',
          ['Active', 'Pending', 'Terminated', 'Expired'],
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'description',
          'Description',
          'Enter a description of the contract',
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
          'Certification Name',
          'Enter the name of the certification',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'certificationNumber',
          'Certification Number',
          'Enter the certification reference number',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'issuingAuthority',
          'Issuing Authority',
          'Enter the name of the issuing authority',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'issueDate',
          'Issue Date',
        ),
        const SizedBox(height: 16),
        _buildCheckboxField(
          'hasRestrictions',
          'Has Restrictions',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'notes',
          'Notes',
          'Enter any additional notes',
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
          'Inspection Location',
          'Enter the location that was inspected',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'inspectionDate',
          'Inspection Date',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'inspector',
          'Inspector',
          'Enter the name of the inspector',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'result',
          'Inspection Result',
          ['Pass', 'Pass with Conditions', 'Fail', 'Incomplete'],
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'findings',
          'Findings',
          'Enter inspection findings',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'recommendations',
          'Recommendations',
          'Enter recommendations',
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
          'Assessment Title',
          'Enter the title of this risk assessment',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'assessmentDate',
          'Assessment Date',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'assessor',
          'Assessor',
          'Enter the name of the assessor',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'riskLevel',
          'Overall Risk Level',
          ['Low', 'Medium', 'High', 'Critical'],
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'hazards',
          'Identified Hazards',
          'List the identified hazards',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'controls',
          'Control Measures',
          'List the control measures',
        ),
        const SizedBox(height: 16),
        _buildCheckboxField(
          'requiresFollowUp',
          'Requires Follow-up',
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
          'Title',
          'Enter a title',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'reference',
          'Reference',
          'Enter a reference number',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'documentDate',
          'Document Date',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'notes',
          'Notes',
          'Enter any additional notes',
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
                        : 'Select a date',
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

  Widget _buildDropdownField(
      String fieldKey,
      String label,
      List<String> options,
      ) {
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
              child: Text(option),
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