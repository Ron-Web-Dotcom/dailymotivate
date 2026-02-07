import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AIPreferencesWidget extends StatefulWidget {
  const AIPreferencesWidget({super.key});

  @override
  State<AIPreferencesWidget> createState() => _AIPreferencesWidgetState();
}

class _AIPreferencesWidgetState extends State<AIPreferencesWidget> {
  final List<Map<String, dynamic>> _tones = [
    {'name': 'Inspirational', 'icon': 'auto_awesome', 'value': 'inspirational'},
    {
      'name': 'Humorous',
      'icon': 'sentiment_very_satisfied',
      'value': 'humorous',
    },
    {'name': 'Philosophical', 'icon': 'psychology', 'value': 'philosophical'},
    {'name': 'Practical', 'icon': 'lightbulb', 'value': 'practical'},
    {'name': 'Energetic', 'icon': 'bolt', 'value': 'energetic'},
  ];

  String _selectedTone = 'inspirational';
  bool _enablePersonalization = false;
  String _userName = '';
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTone = prefs.getString('ai_tone') ?? 'inspirational';
      _enablePersonalization = prefs.getBool('ai_personalization') ?? false;
      _userName = prefs.getString('user_name') ?? '';
      _nameController.text = _userName;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_tone', _selectedTone);
    await prefs.setBool('ai_personalization', _enablePersonalization);
    await prefs.setString('user_name', _userName);
  }

  void _selectTone(String tone) {
    setState(() {
      _selectedTone = tone;
    });
    _savePreferences();
  }

  void _togglePersonalization(bool value) {
    setState(() {
      _enablePersonalization = value;
    });
    _savePreferences();
  }

  void _saveName() {
    setState(() {
      _userName = _nameController.text.trim();
    });
    _savePreferences();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'psychology',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'AI Preferences',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Customize your AI-generated quotes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Quote Tone',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _tones.map((tone) {
              final isSelected = _selectedTone == tone['value'];
              return InkWell(
                onTap: () => _selectTone(tone['value'] as String),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: tone['icon'] as String,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        size: 18,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        tone['name'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Divider(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalization',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Tailor quotes to your name',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enablePersonalization,
                onChanged: _togglePersonalization,
              ),
            ],
          ),
          if (_enablePersonalization) ...[
            SizedBox(height: 2.h),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: CustomIconWidget(
                    iconName: 'check',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: _saveName,
                ),
              ),
              onSubmitted: (_) => _saveName(),
            ),
          ],
        ],
      ),
    );
  }
}
