import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/delivery_fee_value.dart';
import 'package:raheeq_main/common_widgets/payment_method_badge.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:raheeq_main/services/deep_link_service.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentDetailsPage extends StatefulWidget {
  final OrderFinancials financials;
  final OrderResponseModel order;
  final bool isAr;
  const PaymentDetailsPage({
    super.key,
    required this.order,
    required this.financials,
    required this.isAr,
  });

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  Future<void> _openInvoice(String invoiceUrl) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: WaterLoadingIndicator(size: 30)),
    );

    try {
      final uri = _resolveInvoiceUri(invoiceUrl);

      // Force a .pdf extension on the local file regardless of the source
      // URL's shape, so the OS resolves the "open with" intent to a PDF
      // viewer instead of falling back to a browser.
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/invoice_'
          '${widget.order.subOrderNumber}'
          '.pdf';

      final response = await Dio().download(
        uri.toString(),
        filePath,
        options: Options(headers: await _invoiceHeaders(uri)),
      );

      // Whatever the server sent is now sitting in a file named .pdf, which
      // every viewer will take at face value. An HTML error page or a JSON
      // envelope saved under that name is what a reader reports back as "of
      // invalid format", so check the bytes before handing the file over.
      final file = File(filePath);
      final problem = await _pdfProblem(file);
      if (problem != null) {
        await _logBadInvoice(uri, response, file, problem);
        if (mounted) Navigator.pop(context); // hide loading
        await _openInvoiceInBrowser(uri);
        return;
      }

      if (mounted) Navigator.pop(context); // hide loading

      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done && mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.could_not_open_invoice,
        );
      }
    } catch (e) {
      log('Error opening invoice: $e', name: 'BookingDetailsPage', error: e);
      if (mounted) {
        Navigator.pop(context); // hide loading
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.could_not_open_invoice,
        );
      }
    }
  }

  /// Last resort when the download did not produce a PDF: hand the URL to the
  /// browser. What the API returns today is a Daftra portal page rather than a
  /// file, and a browser can at least render it — with the session cookies and
  /// the login form the download had no way of carrying.
  Future<void> _openInvoiceInBrowser(Uri uri) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      log(
        'Could not open the invoice in a browser: $e',
        name: 'BookingDetailsPage',
        error: e,
      );
    }

    if (!launched && mounted) {
      CustomSnackbar.show(
        context: context,
        isError: true,
        message: AppLocalizations.of(context)!.could_not_open_invoice,
      );
    }
  }

  /// The invoice URL as the API gave it, resolved against the API host when it
  /// arrives as a path rather than a full URL.
  Uri _resolveInvoiceUri(String invoiceUrl) {
    final uri = Uri.parse(invoiceUrl.trim());
    if (uri.hasScheme) return uri;
    return Uri.parse(ApiService.baseUrl).resolve(invoiceUrl.trim());
  }

  /// Sends the session token only for invoices served by our own API. A
  /// presigned storage URL carries its own credentials in the query string and
  /// rejects the request outright if an Authorization header is added on top.
  Future<Map<String, String>?> _invoiceHeaders(Uri uri) async {
    if (uri.host != Uri.parse(ApiService.baseUrl).host) return null;
    final token = AuthStorage.accessToken;
    if (token == null) return null;
    return {'Authorization': 'Bearer $token'};
  }

  /// [count] bytes of [file] starting at [from], or fewer when it is shorter.
  Future<List<int>> _readBytes(
    File file, {
    int from = 0,
    int count = 1024,
  }) async {
    if (!await file.exists()) return const [];
    final handle = await file.open();
    try {
      if (from > 0) await handle.setPosition(from);
      return await handle.read(count);
    } finally {
      await handle.close();
    }
  }

  /// What is wrong with the downloaded invoice, or null when it is a PDF a
  /// reader will accept.
  ///
  /// Both ends are checked. The header can sit a little way in — some
  /// generators emit a byte order mark or a stray newline first, which readers
  /// tolerate — while a missing trailer means the download was cut short, and
  /// a half-written PDF is reported by readers the same way a non-PDF is.
  Future<String?> _pdfProblem(File file) async {
    if (!await file.exists()) return 'no file was written';

    final length = await file.length();
    if (length == 0) return 'the file is empty';

    final head = String.fromCharCodes(await _readBytes(file, count: 1024));
    if (!head.contains('%PDF-')) return 'not a PDF';

    final tailStart = length > 1024 ? length - 1024 : 0;
    final tail = String.fromCharCodes(
      await _readBytes(file, from: tailStart, count: 1024),
    );
    if (!tail.contains('%%EOF')) return 'truncated: no %%EOF trailer';

    return null;
  }

  Future<void> _logBadInvoice(
    Uri uri,
    Response<dynamic> response,
    File file,
    String problem,
  ) async {
    final length = await file.exists() ? await file.length() : 0;
    final head = String.fromCharCodes(await _readBytes(file, count: 200));
    log(
      'Invoice is not usable — $problem.\n'
      'url: $uri\n'
      'status: ${response.statusCode}\n'
      'content-type: ${response.headers.value('content-type')}\n'
      'content-length header: ${response.headers.value('content-length')}\n'
      'bytes written: $length\n'
      'starts with: $head',
      name: 'BookingDetailsPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(
              hasBackgroundColor: true,
              isStartAligned: true,
              title: AppLocalizations.of(context)!.payment_details,
              subtitle: "",
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previousChildren, ?currentChild],
                    );
                  },
                  child: Column(
                    children: [
                      _buildContent(context),
                      Builder(
                        builder: (context) {
                          final bool showInvoice =
                              widget.order.invoiceUrl != null &&
                              widget.order.invoiceUrl!.isNotEmpty;

                          if (showInvoice) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                if (true)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.buttonBlueDark,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      onPressed: () => _openInvoice(
                                        widget.order.invoiceUrl!,
                                      ),
                                      icon: const Icon(
                                        Icons.receipt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.view_invoice,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (widget.order.parentOrder?.paymentMethod != null &&
                widget.order.parentOrder!.paymentMethod.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.payment_method,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  // The badge carries the method's own name and colour,
                  // so WALLET, FREE and MANUAL — which have no logo —
                  // still read as something rather than a blank space.
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: PaymentMethodBadge(
                        method: widget.order.parentOrder!.paymentMethod,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 12),
            ],
            if (widget.order.parentOrder?.paymentStatus != null &&
                widget.order.parentOrder!.paymentStatus.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.payment_status,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: PaymentStatusBadge(
                        status: widget.order.parentOrder!.paymentStatus,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            _buildFinancialRow(
              context,
              AppLocalizations.of(context)!.amount_value,
              widget.order.financials!.amount,
              widget.isAr,
            ),
            const SizedBox(height: 12),
            _buildDeliveryFeeRow(
              context,
              widget.order.financials!,
              widget.isAr,
            ),

            // The rate rides in the label so the customer can see which
            // VAT the amount was worked out at.
            if (widget.order.financials!.vatAmount > 0) ...[
              const SizedBox(height: 12),
              _buildFinancialRow(
                context,
                AppLocalizations.of(context)!.vat_with_percentage(
                  Formatters.formatPercentage(widget.order.financials!.vatRate),
                ),
                widget.order.financials!.vatAmount,
                widget.isAr,
              ),
            ],

            // Deductions are shown as negatives so the rows add up to
            // the total that was actually charged.
            if (widget.order.financials!.discountAmount > 0) ...[
              const SizedBox(height: 12),
              _buildFinancialRow(
                context,
                AppLocalizations.of(context)!.discount,
                -widget.order.financials!.discountAmount,
                widget.isAr,
              ),
            ],
            if (widget.order.financials!.walletAmount > 0) ...[
              const SizedBox(height: 12),
              _buildFinancialRow(
                context,
                AppLocalizations.of(context)!.wallet_applied,
                -widget.order.financials!.walletAmount,
                widget.isAr,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Color(0xFFEAEFF2), height: 1),
            ),
            // "Total Paid" rather than "Total Amount": on a wallet or
            // free order the deduction rows above bring this to 0, and
            // the label has to say that nothing was charged.
            _buildFinancialRow(
              context,
              AppLocalizations.of(context)!.total_paid,
              (widget.order.financials!.totalAmount),
              widget.isAr,
              isTotal: true,
            ),
            const SizedBox(height: 8),
            // An admin created this order offline, so the customer never
            // saw a payment screen — say where the money came from.
            if (widget.order.parentOrder?.paymentMethod.toUpperCase() ==
                'MANUAL') ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.manual_payment_note,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryFeeRow(
    BuildContext context,
    OrderFinancials financials,
    bool isAr,
  ) {
    final isFree = financials.hasFreeDelivery;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.delivery_fee,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        DeliveryFeeValue(
          isFree: isFree,
          amount: isFree
              ? financials.strikethroughDeliveryFee
              : financials.deliveryFee,
          baseStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(
    BuildContext context,
    String label,
    double amount,
    bool isAr, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.buttonBlueDark : Colors.grey[700],
          ),
        ),
        Text(
          '\u202A${AppLocalizations.of(context)!.sar_currency} ${Formatters.formatPrice(amount)}\u202C',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.buttonBlueDark : Colors.black,
          ),
        ),
      ],
    );
  }
}
