import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51BTUDGJAJfZb9HEBwDg86TN1KNprHjkfipXmEDMb0gSCassK5T3ZfxsAbcgKVmAIXF7oZ6ItlZZbXO6idTHE67IM007EwQ4uN3';

  // if (Stripe.publishableKey.isEmpty) {
  //   throw const StripeConfigException('Publishable key not set');
  // }

  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stripe Payment Demo',
      home: StripePaymentScreen(),
    );
  }
}

class StripePaymentScreen extends StatefulWidget {
  const StripePaymentScreen({super.key});

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  Map<String, dynamic>? paymentIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Make Payment'),
          onPressed: () async {
            await makePayment();
          },
        ),
      ),
    );
  }

  Future<void> makePayment() async {
    try {
      if (Stripe.publishableKey.isEmpty) {
        showErrorAndSuccess("Publishable key not set");
      }

      paymentIntent = await createPaymentIntent(
        amount: "10000",
        currency: "INR",
        name: "Suryanarayan Developer",
        address: "Bhiwandi",
        pin: "400001",
        city: "Pune",
        state: "Maharashtra",
        country: "India",
      );

      if (paymentIntent != null) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            customFlow: false,
            paymentIntentClientSecret: paymentIntent!['client_secret'],
            merchantDisplayName: 'GyanKosh',
          ),
        );

        displayPaymentSheet();
      } else {
        // Handle case where paymentIntent is null
        showErrorAndSuccess("Error: Payment intent could not be created.");
      }
    } catch (e) {
      showErrorAndSuccess("An unexpected error occurred: ${e.toString()}");
    }
  }

  void showErrorAndSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      showErrorAndSuccess("Paid successfully");
      paymentIntent = null;
    } catch (e) {
      showErrorAndSuccess("Payment Cancelled");
      paymentIntent = null;
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String name,
    required String address,
    required String pin,
    required String city,
    required String state,
    required String country,
    required String currency,
    required String amount,
  }) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
        'description': "Test Donation",
        'shipping[name]': name,
        'shipping[address][line1]': address,
        'shipping[address][postal_code]': pin,
        'shipping[address][city]': city,
        'shipping[address][state]': state,
        'shipping[address][country]': country,
      };
      var secretKey = "sk_test_tR3PYbcVNZZ796tH88S4VQ2u";
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return jsonDecode(response.body.toString());
    } catch (err) {
      showErrorAndSuccess("Error charging user: ${err.toString()}");
      return {};
    }
  }
}
