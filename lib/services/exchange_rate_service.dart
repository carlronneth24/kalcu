import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

/// Fetches live exchange rates from the Frankfurter API (free, no API key,
/// ECB-sourced, updated daily). Falls back to the last successfully cached
/// rates (stored locally via Hive) if there's no internet, and finally to
/// a small set of hardcoded rates if there's no cache at all yet.
class ExchangeRateService {
  static const _apiUrl = 'https://api.frankfurter.dev/v1/latest?base=USD';
  static const _currenciesUrl = 'https://api.frankfurter.dev/v1/currencies';
  static const _boxName = 'exchangeRatesBox';

  // Last-resort fallback if the API has never been reachable on this device.
  static const Map<String, double> _kFallbackRatesToUsd = {
    'USD': 1.0,
    'PHP': 0.0177,
    'EUR': 1.08,
    'JPY': 0.0064,
    'GBP': 1.27,
    'AUD': 0.65,
  };

  // Fallback names for all ~31 currencies Frankfurter/ECB supports, used
  // only if the /currencies endpoint has never been reachable on this device.
  static const Map<String, String> _kFallbackCurrencyNames = {
    'AUD': 'Australian dollar',
    'BGN': 'Bulgarian lev',
    'BRL': 'Brazilian real',
    'CAD': 'Canadian dollar',
    'CHF': 'Swiss franc',
    'CNY': 'Chinese yuan',
    'CZK': 'Czech koruna',
    'DKK': 'Danish krone',
    'EUR': 'Euro',
    'GBP': 'British pound',
    'HKD': 'Hong Kong dollar',
    'HUF': 'Hungarian forint',
    'IDR': 'Indonesian rupiah',
    'ILS': 'Israeli shekel',
    'INR': 'Indian rupee',
    'ISK': 'Icelandic krona',
    'JPY': 'Japanese yen',
    'KRW': 'South Korean won',
    'MXN': 'Mexican peso',
    'MYR': 'Malaysian ringgit',
    'NOK': 'Norwegian krone',
    'NZD': 'New Zealand dollar',
    'PHP': 'Philippine peso',
    'PLN': 'Polish zloty',
    'RON': 'Romanian leu',
    'SEK': 'Swedish krona',
    'SGD': 'Singapore dollar',
    'THB': 'Thai baht',
    'TRY': 'Turkish lira',
    'USD': 'United States dollar',
    'ZAR': 'South African rand',
  };

  static Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  /// Returns a map of currency code -> value of 1 unit of that currency in USD.
  /// Also returns whether the data came from a live fetch (vs cache/fallback)
  /// and the timestamp of the rates being used.
  static Future<ExchangeRateResult> getRatesToUsd() async {
    final box = await _openBox();

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final ratesFromUsd = Map<String, dynamic>.from(data['rates']);

        final ratesToUsd = <String, double>{'USD': 1.0};
        ratesFromUsd.forEach((code, rate) {
          final r = (rate as num).toDouble();
          if (r != 0) ratesToUsd[code] = 1 / r;
        });

        final now = DateTime.now();
        await box.put('rates', ratesToUsd);
        await box.put('timestamp', now.toIso8601String());

        return ExchangeRateResult(
          rates: ratesToUsd,
          isLive: true,
          timestamp: now,
        );
      }
    } catch (_) {
      // No internet, blocked, timed out, etc. — fall through to cache.
    }

    // Try cached rates from a previous successful fetch.
    final cachedRates = box.get('rates');
    final cachedTimestamp = box.get('timestamp');
    if (cachedRates != null) {
      return ExchangeRateResult(
        rates: Map<String, double>.from(cachedRates),
        isLive: false,
        timestamp: cachedTimestamp != null
            ? DateTime.tryParse(cachedTimestamp as String)
            : null,
      );
    }

    // No cache and no internet — last resort static rates.
    return ExchangeRateResult(
      rates: _kFallbackRatesToUsd,
      isLive: false,
      timestamp: null,
    );
  }

  /// Returns a map of currency code -> full display name (e.g. "PHP" ->
  /// "Philippine Peso") for every currency Frankfurter supports (~31).
  static Future<Map<String, String>> getCurrencyNames() async {
    final box = await _openBox();

    try {
      final response = await http
          .get(Uri.parse(_currenciesUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final names = data.map((k, v) => MapEntry(k, v.toString()));
        await box.put('currencyNames', names);
        return names;
      }
    } catch (_) {
      // fall through to cache/fallback
    }

    final cached = box.get('currencyNames');
    if (cached != null) {
      return Map<String, String>.from(cached);
    }

    return _kFallbackCurrencyNames;
  }
}

class ExchangeRateResult {
  final Map<String, double> rates;
  final bool isLive;
  final DateTime? timestamp;

  ExchangeRateResult({
    required this.rates,
    required this.isLive,
    required this.timestamp,
  });
}