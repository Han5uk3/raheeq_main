import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/new.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
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
            message: (res.data is Map && res.data['message'] != null)
                ? res.data['message']
                : 'Feedback sent successfully',
          );
          _suggestionController.clear();
        }
      }
    } catch (e) {
      log('Feedback API error: $e', name: 'SuggestionsPage', error: e);
      if (mounted) {
        String errorMessage = 'Failed to send feedback';
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null &&
            e.response?.data['message'] == 'Feedback submitted successfully') {
          errorMessage = AppLocalizations.of(
            context,
          )!.feedback_submitted_successfully;
        } else if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null &&
            e.response?.data['message'] != 'Feedback submitted successfully') {
          errorMessage = e.response?.data['message'];
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
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
              color: AppColors.buttonBlueDark,
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
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                      ),
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
                        hintStyle: TextStyle(
                          color: AppColors.black.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.buttonBlueDark,
                            width: 1.5,
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
                                waveColor1: AppColors.white,
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
