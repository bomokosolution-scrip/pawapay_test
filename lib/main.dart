import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const token = String.fromEnvironment('PAWAPAY_TOKEN');
const baseUrl = 'https://api.sandbox.pawapay.io';

void main() => runApp(const MaterialApp(home: PayPage()));

class PayPage extends StatefulWidget {
  const PayPage({super.key});
  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final phone = TextEditingController(); // ex: 243812345678 (sans +)
  final amount = TextEditingController(text: '100');
  String provider = 'VODACOM_MPESA_COD';
  String currency = 'CDF';
  bool loading = false;
  String status = '';

  Map<String, String> get headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<void> pay() async {
    if (token.isEmpty) {
      setState(() => status = 'Token manquant (--dart-define=PAWAPAY_TOKEN=...)');
      return;
    }
    setState(() { loading = true; status = 'Envoi de la demande...'; });
    final depositId = const Uuid().v4();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/v2/deposits'),
        headers: headers,
        body: jsonEncode({
          'depositId': depositId,
          'amount': amount.text.trim(),
          'currency': currency,
          'payer': {
            'type': 'MMO',
            'accountDetails': {
              'phoneNumber': phone.text.trim(),
              'provider': provider,
            },
          },
          'customerMessage': 'Test paiement',
        }),
      );
      final body = jsonDecode(res.body);
      if (body['status'] == 'ACCEPTED') {
        setState(() => status = 'Demande envoyée. Confirmez sur le téléphone...');
        await poll(depositId);
      } else {
        setState(() => status = 'Refusé : ${res.body}');
      }
    } catch (e) {
      setState(() => status = 'Erreur : $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> poll(String id) async {
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final res = await http.get(Uri.parse('$baseUrl/v2/deposits/$id'),
          headers: headers);
      final body = jsonDecode(res.body);
      final s = body['data']?['status'];
      if (s == 'COMPLETED' || s == 'FAILED') {
        setState(() => status = 'Résultat : $s');
        return;
      }
      setState(() => status = 'En attente... ($s)');
    }
    setState(() => status = 'Délai dépassé');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Test PawaPay')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Numéro (ex: 243812345678)'),
            ),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant'),
            ),
            DropdownButtonFormField<String>(
              value: provider,
              decoration: const InputDecoration(labelText: 'Opérateur'),
              items: const [
                'VODACOM_MPESA_COD',
                'AIRTEL_COD',
                'ORANGE_COD',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => provider = v!),
            ),
            DropdownButtonFormField<String>(
              value: currency,
              decoration: const InputDecoration(labelText: 'Devise'),
              items: const ['CDF', 'USD']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => currency = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : pay,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Payer'),
            ),
            const SizedBox(height: 20),
            Text(status),
          ]),
        ),
      );
}
