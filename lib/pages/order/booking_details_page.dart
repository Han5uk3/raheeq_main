import 'dart:convert';
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
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:raheeq_main/pages/order/proof_media_viewer_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/services/deep_link_service.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:raheeq_main/utils/formatters.dart';

class BookingDetailsPage extends StatefulWidget {
  final String orderId;
  final bool autoPlayVideo;

  const BookingDetailsPage({
    super.key,
    required this.orderId,
    this.autoPlayVideo = false,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  OrderResponseModel? _order;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      log(
        'Fetching order details for orderId: ${widget.orderId}',
        name: 'BookingDetailsPage',
      );
      final response = await ApiService().getOrderDetails(widget.orderId);
      log(
        'Order details response (${response.statusCode}): ${jsonEncode(response.data)}',
        name: 'BookingDetailsPage',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _order = OrderResponseModel.fromJson(response.data['data']);
          _isLoading = false;
        });

        if (widget.autoPlayVideo &&
            _order?.deliveryProof != null &&
            _order!.deliveryProof!['deliveryVideo'] != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                List<ProofMediaItem> mediaItems = _getMediaItems(_order!);
                int videoIndex = mediaItems.indexWhere((item) => item.isVideo);
                if (videoIndex != -1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProofMediaViewerPage(
                        mediaItems: mediaItems,
                        initialIndex: videoIndex,
                        orderNumber: _order?.subOrderNumber,
                      ),
                    ),
                  );
                }
              }
            });
          });
        }
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Failed to load order details';
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error fetching order details: $e', name: 'BookingDetailsPage', error: e);
      String errorMessage = 'Failed to load order details';
      if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'].toString();
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

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
          '${_order?.subOrderNumber ?? DateTime.now().millisecondsSinceEpoch}'
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
  Future<List<int>> _readBytes(File file, {int from = 0, int count = 1024}) async {
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
    // If order_details key doesn't exist, use fallback
    String title = "";
    try {
      title = AppLocalizations.of(context)!.order_details;
    } catch (_) {
      title = "Order Details";
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(
              hasBackgroundColor: true,
              isStartAligned: true,
              title: title,
              subtitle: _order?.subOrderNumber ?? "",
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
                  child: _buildContent(isAr),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required TextStyle style}) {
    return Text(title, style: style);
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }

  Widget _buildContent(bool isAr) {
    if (_isLoading) {
      return Padding(
        key: const ValueKey('loader'),
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? AppLocalizations.of(context)!.error_title,
              style: const TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: _fetchOrderDetails,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    final order = _order!;

    return Padding(
      key: const ValueKey('content'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final bool showInvoice =
                  order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty;
              final bool showReorder =
                  order.status.toUpperCase() == 'CONFIRMED';

              if (!showInvoice && !showReorder) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  children: [
                    if (showInvoice)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlueDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _openInvoice(order.invoiceUrl!),
                          icon: const Icon(
                            Icons.receipt,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context)!.view_invoice,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (showInvoice && showReorder) const SizedBox(width: 12),
                    if (showReorder)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlueDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            DeepLinkService().handleReorder(order.id);
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context)!.reorder,
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
          // Product details
          if (order.product != null) ...[
            _buildPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.product_details,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: order.product!.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? order.product!.nameAr
                                  : order.product!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context)!.quantity}: ${order.product!.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Target and Location details
          if (order.target != null ||
              order.locationDetails != null ||
              order.deliveredLocationDetails != null) ...[
            const SizedBox(height: 12),
            _buildPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.location_details,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (order.target != null) ...[
                    _buildInfoRow(
                      AppLocalizations.of(context)!.location,
                      isAr ? order.target!.labelAr : order.target!.label,
                    ),
                  ],
                  if (order.locationDetails != null &&
                      order.locationDetails!['address'] != null)
                    _buildInfoRow(
                      AppLocalizations.of(context)!.address,
                      order.locationDetails!['address'].toString(),
                    ),
                ],
              ),
            ),
          ],

          if (order.deliveredToDifferentMosque == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.deliveredToDifferentLocation,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.differentMosqueReason != null &&
                            order.differentMosqueReason!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${AppLocalizations.of(context)!.reasonForDifferentLocation}: ${order.differentMosqueReason}',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Delivery Proofs
          _buildDeliveryProofs(order),
          const SizedBox(height: 12),

          // Gift Card details
          if (order.giftCard != null) ...[
            Builder(
              builder: (context) {
                final String? giftCardUrl =
                    order.giftCard!['generatedImage'] ??
                    order.giftCard!['image'] ??
                    order.giftCard!['url'] ??
                    order.giftCard!['pdfUrl']; // add fallbacks just in case

                if (giftCardUrl == null) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildPremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            AppLocalizations.of(context)!.gift_card,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    backgroundColor: Colors.black,
                                    appBar: AppBar(
                                      backgroundColor: Colors.black,
                                      iconTheme: const IconThemeData(
                                        color: Colors.white,
                                      ),
                                    ),
                                    body: Center(
                                      child: InteractiveViewer(
                                        child: CachedNetworkImage(
                                          imageUrl: giftCardUrl,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: giftCardUrl,
                                height: 290,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        height: 290,
                                        width: double.infinity,
                                        color: Colors.white,
                                      ),
                                    ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  height: 290,
                                  width: double.infinity,
                                  child: const Center(child: Icon(Icons.error)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          // Delivery Progress
          _buildDeliveryProgressCard(order),
          const SizedBox(height: 12),

          // Payment details
          if (order.financials != null) ...[
            _buildPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.payment_details,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (order.parentOrder?.paymentMethod != null &&
                      order.parentOrder!.paymentMethod.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.payment_method,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        // The badge carries the method's own name and colour,
                        // so WALLET, FREE and MANUAL — which have no logo —
                        // still read as something rather than a blank space.
                        Flexible(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: PaymentMethodBadge(
                              method: order.parentOrder!.paymentMethod,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (order.parentOrder?.paymentStatus != null &&
                      order.parentOrder!.paymentStatus.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.payment_status,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Flexible(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: PaymentStatusBadge(
                              status: order.parentOrder!.paymentStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildFinancialRow(
                    AppLocalizations.of(context)!.amount_value,
                    order.financials!.amount,
                    isAr,
                  ),
                  const SizedBox(height: 12),
                  _buildDeliveryFeeRow(order.financials!, isAr),
               
                  // The rate rides in the label so the customer can see which
                  // VAT the amount was worked out at.
                  if (order.financials!.vatAmount > 0) ...[
                    const SizedBox(height: 12),
                    _buildFinancialRow(
                    AppLocalizations.of(context)!.vat_with_percentage(
                      Formatters.formatPercentage(order.financials!.vatRate),
                    ),
                    order.financials!.vatAmount,
                    isAr,
                  ),
                  ],
                
                  // Deductions are shown as negatives so the rows add up to
                  // the total that was actually charged.
                  if (order.financials!.discountAmount > 0) ...[
                    const SizedBox(height: 12),
                    _buildFinancialRow(
                      AppLocalizations.of(context)!.discount,
                      -order.financials!.discountAmount,
                      isAr,
                    ),
                  ],
                  if (order.financials!.walletAmount > 0) ...[
                    const SizedBox(height: 12),
                    _buildFinancialRow(
                      AppLocalizations.of(context)!.wallet_applied,
                      -order.financials!.walletAmount,
                      isAr,
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
                    AppLocalizations.of(context)!.total_paid,
                    (order.financials!.totalAmount),
                    isAr,
                    isTotal: true,
                  ),
                  // An admin created this order offline, so the customer never
                  // saw a payment screen — say where the money came from.
                  if (order.parentOrder?.paymentMethod.toUpperCase() ==
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
            const SizedBox(height: 12), // spacing at bottom
          ],

          // Customer Review
          if (order.review != null) ...[
            _buildPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.review,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < order.review!.rating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  if (order.review!.reviewText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      order.review!.reviewText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// The delivery fee row, which reads "SAR 25.00  Free" — original struck
  /// through — instead of a bare "SAR 0" when the delivery was free.
  Widget _buildDeliveryFeeRow(OrderFinancials financials, bool isAr) {
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryProgressCard(OrderResponseModel order) {
    final bool isOrderPlaced = true;
    final bool isOutForDelivery =
        order.driver != null ||
        order.status == 'DISPATCHED' ||
        order.status == 'OUT_FOR_DELIVERY' ||
        order.status == 'DELIVERED' ||
        order.status == 'CONFIRMED' ||
        order.status == 'COMPLETED';
    final bool isDelivered =
        order.status == 'CONFIRMED' || order.status == 'COMPLETED';

    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            AppLocalizations.of(context)!.delivery_progress,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTimelineItem(
            title: AppLocalizations.of(context)!.order_placed,
            date: order.createdAt,
            isReached: isOrderPlaced,
            isLast: false,
            icon: Icons.receipt_long,
          ),
          _buildTimelineItem(
            title: AppLocalizations.of(context)!.out_for_delivery,
            date:
                order.assignedAt ??
                ((order.status == 'CONFIRMED' || order.status == 'COMPLETED')
                    ? (order.confirmedAt ?? order.completedAt)
                    : null),
            isReached: isOutForDelivery,
            isLast: false,
            icon: Icons.local_shipping,
          ),
          _buildTimelineItem(
            title: AppLocalizations.of(context)!.delivery_completed,
            date: order.completedAt ?? order.confirmedAt,
            isReached: isDelivered,
            isLast: true,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    DateTime? date,
    required bool isReached,
    required bool isLast,
    required IconData icon,
  }) {
    final Color color = isReached
        ? AppColors.buttonBlueDark
        : Colors.grey[300]!;

    String formattedDate = '';
    if (date != null) {
      formattedDate = Formatters.formatDateTime(context, date);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isReached ? color : Colors.grey[100],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isReached ? AppColors.buttonBlueDark : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
                    color: isReached ? Colors.black : Colors.grey,
                  ),
                ),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ProofMediaItem> _getMediaItems(OrderResponseModel order) {
    if (order.deliveryProof == null || order.deliveryProof!.isEmpty) {
      return [];
    }

    final proofs = order.deliveryProof!;
    List<ProofMediaItem> mediaItems = [];

    if (proofs['mosqueFrontImage'] != null &&
        proofs['mosqueFrontImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.mosque_front,
          fileLabel: 'mosque_front',
          url: proofs['mosqueFrontImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['mosqueInsideImage'] != null &&
        proofs['mosqueInsideImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.mosque_inside,
          fileLabel: 'mosque_inside',
          url: proofs['mosqueInsideImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['packagesImage'] != null &&
        proofs['packagesImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.packages,
          fileLabel: 'product_image',
          url: proofs['packagesImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['deliveryVideo'] != null &&
        proofs['deliveryVideo'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.delivery_video,
          fileLabel: 'video',
          url: proofs['deliveryVideo'],
          isVideo: true,
        ),
      );
    }
    return mediaItems;
  }

  Widget _buildDeliveryProofs(OrderResponseModel order) {
    final mediaItems = _getMediaItems(order);

    if (mediaItems.isEmpty) return const SizedBox.shrink();

    List<Widget> proofItems = [];
    for (int i = 0; i < mediaItems.length; i++) {
      proofItems.add(
        _buildSmallProofCard(mediaItems[i].title, mediaItems[i].url, mediaItems[i].isVideo, i, mediaItems),
      );
    }

    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            AppLocalizations.of(context)!.proof_of_delivery,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (index) {
              if (index.isOdd) {
                return const SizedBox(width: 8.0);
              }
              int itemIndex = index ~/ 2;
              if (itemIndex < proofItems.length) {
                return Expanded(child: proofItems[itemIndex]);
              } else {
                return const Expanded(child: SizedBox.shrink());
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallProofCard(String title, String url, bool isVideo, int index, List<ProofMediaItem> allMedia) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProofMediaViewerPage(
              mediaItems: allMedia,
              initialIndex: index,
              orderNumber: _order?.subOrderNumber,
            ),
          ),
        );
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isVideo)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black12,
                      child: const Icon(
                        Icons.videocam,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  if (isVideo)
                    const Center(
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
              PositionedDirectional(
                top: 40,
                start: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoPreview(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoPlayerWidget(url: url),
              PositionedDirectional(
                top: 40,
                start: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            setState(() {});
            _controller.play();
          })
          .catchError((e) {
            setState(() {
              _isError = true;
            });
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Text(
          "Failed to load video",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Center(
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
