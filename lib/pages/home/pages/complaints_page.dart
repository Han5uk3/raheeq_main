import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:intl/intl.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  final TextEditingController _complaintOtherController =
      TextEditingController();
  bool _isLoading = false;
  bool _complaintError = false;

  List<OrderResponseModel> _orders = [];
  OrderResponseModel? _selectedOrder;
  int _selectedComplaintOption = -1;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await ApiService().getMyOrders();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data']['items'] as List;
        final orders = data
            .map((json) => OrderResponseModel.fromJson(json))
            .toList();
        if (mounted) {
          setState(() {
            _orders = orders;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _complaintOtherController.dispose();
    super.dispose();
  }

  Future<void> _sendComplaint() async {
    if (_selectedOrder == null) return;
    if (_selectedComplaintOption == -1) return;

    String description = '';
    final loc = AppLocalizations.of(context)!;
    if (_selectedComplaintOption == 0) {
      description = loc.complaint_option_1;
    } else if (_selectedComplaintOption == 1) {
      description = loc.complaint_option_2;
    } else if (_selectedComplaintOption == 2) {
      description = loc.complaint_option_3;
    } else if (_selectedComplaintOption == 3) {
      if (_complaintOtherController.text.trim().isEmpty) {
        setState(() => _complaintError = true);
        return;
      }
      description = _complaintOtherController.text.trim();
    }

    setState(() {
      _isLoading = true;
      _complaintError = false;
    });
    try {
      log(
        'Sending complaint API request: subOrderId=${_selectedOrder!.id}, description=$description',
        name: 'ComplaintsPage',
      );
      final res = await ApiService().createComplaint(
        subOrderId: _selectedOrder!.id,
        description: description,
      );
      log(
        'Complaint API response: statusCode=${res.statusCode}, data=${res.data}',
        name: 'ComplaintsPage',
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          String successMessage = 'Complaint sent successfully';
          if (res.data is Map && res.data['message'] != null) {
            successMessage = res.data['message'];
          }
          CustomSnackbar.show(context: context, message: successMessage);
          setState(() {
            _selectedOrder = null;
            _selectedComplaintOption = -1;
            _complaintOtherController.clear();
          });
        }
      }
    } catch (e) {
      log('Complaint API error: $e', name: 'ComplaintsPage', error: e);
      if (mounted) {
        String errorMessage = 'Failed to send complaint';
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
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

  void _showOrderSelectionSheet() {
    showModalBottomSheet(
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _orders.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.no_orders_found,
                        ),
                      )
                    : ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        itemCount: _orders.length,
                        itemBuilder: (ctx, index) {
                          final order = _orders[index];
                          final isAr =
                              Localizations.localeOf(context).languageCode ==
                              'ar';

                          String itemName = '';
                          if (order.product != null) {
                            itemName = isAr
                                ? (order.product!.nameAr.isNotEmpty
                                      ? order.product!.nameAr
                                      : order.product!.name)
                                : (order.product!.name.isNotEmpty
                                      ? order.product!.name
                                      : order.product!.nameAr);
                          }

                          String category = '';
                          if (order.target != null) {
                            category = isAr
                                ? (order.target!.labelAr.isNotEmpty
                                      ? order.target!.labelAr
                                      : order.target!.label)
                                : (order.target!.label.isNotEmpty
                                      ? order.target!.label
                                      : order.target!.labelAr);
                          }

                          final dateFormat = DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          );
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white),
                            ),
                            elevation: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedOrder = order;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            itemName.isNotEmpty
                                                ? itemName
                                                : order.id,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (order.subOrderNumber.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F4F8),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '#${order.subOrderNumber}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.buttonBlueDark,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateFormat.format(
                                            order.createdAt.toLocal(),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (category.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (order.product?.quantity != null &&
                                        order.product!.quantity > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.shopping_basket_outlined,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'x${order.product!.quantity}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    String selectedOrderDisplay = loc.select_order;
    if (_selectedOrder != null) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      String itemName = '';
      if (_selectedOrder!.product != null) {
        itemName = isAr
            ? (_selectedOrder!.product!.nameAr.isNotEmpty
                  ? _selectedOrder!.product!.nameAr
                  : _selectedOrder!.product!.name)
            : (_selectedOrder!.product!.name.isNotEmpty
                  ? _selectedOrder!.product!.name
                  : _selectedOrder!.product!.nameAr);
      }
      String orderIdText = _selectedOrder!.subOrderNumber.isNotEmpty
          ? '#${_selectedOrder!.subOrderNumber}'
          : _selectedOrder!.id;
      selectedOrderDisplay = itemName.isNotEmpty
          ? '$itemName ($orderIdText)'
          : orderIdText;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: loc.complaints,
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
                    GestureDetector(
                      onTap: _showOrderSelectionSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEAEFF2)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedOrderDisplay,
                                style: TextStyle(
                                  color: _selectedOrder != null
                                      ? Colors.black
                                      : Colors.grey,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.select_complaint,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildComplaintOption(0, loc.complaint_option_1),
                    _buildComplaintOption(1, loc.complaint_option_2),
                    _buildComplaintOption(2, loc.complaint_option_3),
                    _buildComplaintOption(3, loc.complaint_option_4),
                    if (_selectedComplaintOption == 3) ...[
                      const SizedBox(height: 12),
                      TextField(
                        cursorColor: AppColors.buttonBlueDark,
                        style: const TextStyle(
                          color: AppColors.buttonBlueDark,
                          fontSize: 12,
                        ),
                        controller: _complaintOtherController,
                        onChanged: (value) {
                          if (_complaintError && value.trim().isNotEmpty) {
                            setState(() => _complaintError = false);
                          }
                        },
                        maxLines: 3,
                        decoration: InputDecoration(
                          errorText: _complaintError
                              ? loc.field_required
                              : null,
                          hintText: loc.enter_complaint_hint,
                          hintStyle: TextStyle(
                            color: AppColors.buttonBlueDark.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.buttonBlueDark),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.buttonBlueDark),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    ElevatedButton(
                      onPressed:
                          (_isLoading ||
                              _selectedOrder == null ||
                              _selectedComplaintOption == -1)
                          ? null
                          : _sendComplaint,
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
                                waveColor1: Colors.white,
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

  Widget _buildComplaintOption(int value, String text) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedComplaintOption = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              _selectedComplaintOption == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedComplaintOption == value
                  ? AppColors.buttonBlueDark
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}
