import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  final TextEditingController _suggestionController = TextEditingController();
  bool _isLoading = false;
  bool _suggestionError = false;

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _sendSuggestion() async {
    if (_suggestionController.text.trim().isEmpty) {
      setState(() => _suggestionError = true);
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestionError = false;
    });
    try {
      log(
        'Sending feedback API request: message=${_suggestionController.text.trim()}',
        name: 'SuggestionsPage',
      );
      final res = await ApiService().createFeedback(
        message: _suggestionController.text.trim(),
      );
      log(
        'Feedback API response: statusCode=${res.statusCode}, data=${res.data}',
        name: 'SuggestionsPage',
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: 'Feedback sent successfully',
          );
          _suggestionController.clear();
        }
      }
    } catch (e) {
      log('Feedback API error: $e', name: 'SuggestionsPage', error: e);
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Failed to send feedback',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: loc.suggestions,
            subtitle: '',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: const Color(0x4D91E3FE),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      cursorColor: AppColors.buttonBlueDark,
                      controller: _suggestionController,
                      onChanged: (value) {
                        if (_suggestionError && value.trim().isNotEmpty) {
                          setState(() => _suggestionError = false);
                        }
                      },
                      maxLines: 4,
                      decoration: InputDecoration(
                        errorText: _suggestionError ? loc.field_required : null,
                        hintText: loc.your_suggestions_hint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEAEFF2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEAEFF2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.buttonBlue,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendSuggestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBlueDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: WaterLoadingIndicator(
                                dropletBackgroundColor: AppColors.white,
                              ),
                            )
                          : Text(
                              loc.send,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
