import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/primary_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  Map<String, dynamic>? _activePurchasePackage;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Always clean up SDK connections
    super.dispose();
  }

  Future<void> _initiatePurchase(Map<String, dynamic> package) async {
    _activePurchasePackage = package;
    final double amount = (package['price'] as num).toDouble();
    final int scans = (package['scans'] as num).toInt();

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (provider.isDemoMode) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.payment_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Demo Payment'),
            ],
          ),
          content: Text(
            'Would you like to simulate a successful purchase of the ${package['title']} package (${package['scans']} Scans) for ₹${package['price']}?',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                LoadingDialog.show(context, message: 'Adding scans…');

                final success = await provider.verifyPayment(
                  orderId: "demo_order_${DateTime.now().millisecondsSinceEpoch}",
                  paymentId: "demo_pay_${DateTime.now().millisecondsSinceEpoch}",
                  signature: "demo_signature",
                  scansPurchased: scans,
                  amount: amount,
                );

                if (!mounted) return;
                LoadingDialog.hide(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully added $scans scans (Demo Mode).'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  Navigator.pop(context); // Navigate back to scanner
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simulate Success'),
            ),
          ],
        ),
      );
      return;
    }
    
    // 1. Show order creation progress
    LoadingDialog.show(context, message: 'Preparing your order…');

    // 2. Generate Razorpay order on backend
    final order = await provider.createOrder(amount, scans);

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to initiate purchase.'),
          backgroundColor: AppColors.criticalityEmergency,
        ),
      );
      return;
    }

    // 3. Trigger Razorpay checkout form
    final options = {
      'key': order.key,
      'amount': order.amount, // in paise
      'name': 'Pet Scan AI',
      'order_id': order.orderId,
      'description': 'Purchase ${package['title']} Package ($scans Scans)',
      'timeout': 300, // 5 minutes
      'prefill': {
        'email': provider.currentUser?.email ?? '',
        'name': provider.currentUser?.name ?? '',
      },
      'theme': {
        'color': '#10B981', // Emerald green primary color
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment client initialization failed: $e'),
          backgroundColor: AppColors.criticalityEmergency,
        ),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (response.paymentId == null || response.orderId == null || response.signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment response metadata.'),
          backgroundColor: AppColors.criticalityEmergency,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    LoadingDialog.show(context, message: 'Confirming payment…');

    final pkg = _activePurchasePackage;
    final double amount = pkg != null ? (pkg['price'] as num).toDouble() : 0.0;
    final int scans = pkg != null ? (pkg['scans'] as num).toInt() : 0;

    // Verify payment signature on backend
    final success = await provider.verifyPayment(
      orderId: response.orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
      scansPurchased: scans,
      amount: amount,
    );

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase successful! Scan balance updated.'),
          backgroundColor: AppColors.criticalityLow,
        ),
      );
      // Return back to scan form
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Payment signature verification failed.'),
          backgroundColor: AppColors.criticalityEmergency,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "User cancelled transaction"}'),
        backgroundColor: AppColors.criticalityEmergency,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional implementation: handle other standard external wallet redirects (e.g. Paytm)
  }

  @override
  Widget build(BuildContext context) {
    // Load packages dynamically from Constants (configured for easy future backend migrations)
    final packages = AppConstants.scanPackages;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Buy scans'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        children: [
          Text('Top up your scans', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick a package and get back to checking on your pet.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          ...List.generate(packages.length, (index) {
            final pkg = packages[index];
            final isPopular =
                pkg['title'].toString().toLowerCase() == 'popular';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PackageCard(
                title: pkg['title'].toString(),
                scans: pkg['scans'].toString(),
                price: pkg['price'].toString(),
                isPopular: isPopular,
                onSelect: () => _initiatePurchase(pkg),
              ),
            ).animate(delay: (index * 70).ms).fadeIn(
              duration: AppDurations.slow,
            ).moveY(begin: 16, end: 0, curve: Curves.easeOutCubic);
          }),
        ],
      ),
    );
  }
}

/// One purchase option. The "popular" package gets the gradient treatment so
/// it reads as the recommended choice.
class _PackageCard extends StatelessWidget {
  final String title;
  final String scans;
  final String price;
  final bool isPopular;
  final VoidCallback onSelect;

  const _PackageCard({
    required this.title,
    required this.scans,
    required this.price,
    required this.isPopular,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGradient = isPopular ? Colors.white : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isPopular ? AppColors.gradientPrimary : null,
        color: isPopular ? null : AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        border: isPopular
            ? null
            : Border.all(color: AppColors.alpha(AppColors.border, 0.8)),
        boxShadow: isPopular
            ? AppShadows.glow(AppColors.teal, opacity: 0.3)
            : AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: onGradient,
                        ),
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text(
                          'POPULAR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.ink,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$scans scans',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPopular
                        ? AppColors.alpha(Colors.white, 0.8)
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '₹$price',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: onGradient,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            text: 'Select',
            expand: false,
            height: 46,
            variant: isPopular ? ButtonVariant.filled : ButtonVariant.tonal,
            backgroundColor: isPopular ? Colors.white : AppColors.primary,
            textColor: AppColors.primaryDark,
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}
