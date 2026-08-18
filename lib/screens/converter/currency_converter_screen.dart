import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/calculator_button.dart';
import '../../services/exchange_rate_service.dart';
import '../history/history_screen.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  String _fromCode = 'PHP';
  String _toCode = 'USD';
  String _amountText = '0'; // raw typed amount for the "from" field

  Map<String, double> _ratesToUsd = {};
  Map<String, String> _currencyNames = {};
  bool _isLoading = true;
  bool _isLive = false;
  DateTime? _ratesTimestamp;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ExchangeRateService.getRatesToUsd(),
      ExchangeRateService.getCurrencyNames(),
    ]);
    if (!mounted) return;
    final rateResult = results[0] as ExchangeRateResult;
    final names = results[1] as Map<String, String>;
    setState(() {
      _ratesToUsd = rateResult.rates;
      _currencyNames = names;
      _isLive = rateResult.isLive;
      _ratesTimestamp = rateResult.timestamp;
      _isLoading = false;
    });
  }

  String get _convertedText {
    if (_ratesToUsd.isEmpty) return '0';
    final amount = double.tryParse(_amountText) ?? 0;
    final fromRate = _ratesToUsd[_fromCode] ?? 0;
    final toRate = _ratesToUsd[_toCode] ?? 1;
    final result = amount * fromRate / toRate;
    return _formatResult(result);
  }

  String _formatResult(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e12) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String get _statusText {
    if (_isLoading) return 'Updating rates…';
    if (_ratesTimestamp == null) return 'Offline — using default rates';
    final t = _ratesTimestamp!;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return _isLive
        ? 'Live rates · updated $timeStr'
        : 'Offline · showing rates from $timeStr';
  }

  void _onDigitPressed(String digit) {
    setState(() {
      if (_amountText == '0') {
        _amountText = digit;
      } else {
        _amountText += digit;
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (!_amountText.contains('.')) {
        _amountText += '.';
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _amountText = '0';
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_amountText.length > 1) {
        _amountText = _amountText.substring(0, _amountText.length - 1);
      } else {
        _amountText = '0';
      }
    });
  }

  void _handleTap(String label) {
    HapticFeedback.lightImpact();
    switch (label) {
      case 'AC':
        _onClearPressed();
        break;
      case '←':
        _onBackspacePressed();
        break;
      case '.':
        _onDecimalPressed();
        break;
      case '+':
      case '-':
      case 'x':
      case '/':
      case '%':
      case '=':
        // Amount entry only — operators aren't meaningful here.
        break;
      default:
        _onDigitPressed(label);
    }
  }

  Future<void> _pickCurrency({required bool isFromField}) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF191818),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CurrencyPickerSheet(
          currencyNames: _currencyNames,
          selectedCode: isFromField ? _fromCode : _toCode,
        );
      },
    );

    if (selected == null) return;
    setState(() {
      if (isFromField) {
        _fromCode = selected;
      } else {
        _toCode = selected;
      }
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textWhite, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Currency',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppColors.textWhite, size: 30),
                    onPressed: _openHistory,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _statusText,
                    style: const TextStyle(
                      color: Color(0xFF4C4C4C),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _isLoading ? null : _loadRates,
                    child: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEC8116),
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Color(0xFFEC8116),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCurrencyRow(
                code: _fromCode,
                amountText: _amountText,
                isFromField: true,
              ),
              const SizedBox(height: 24),
              _buildCurrencyRow(
                code: _toCode,
                amountText: _convertedText,
                isFromField: false,
              ),
              const Spacer(),
              _buildRow(['AC', '←', '%', '/']),
              const SizedBox(height: 12),
              _buildRow(['7', '8', '9', 'x']),
              const SizedBox(height: 12),
              _buildRow(['4', '5', '6', '-']),
              const SizedBox(height: 12),
              _buildRow(['1', '2', '3', '+']),
              const SizedBox(height: 12),
              _buildBottomRow(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyRow({
    required String code,
    required String amountText,
    required bool isFromField,
  }) {
    final name = _currencyNames[code] ?? code;
    return InkWell(
      onTap: () => _pickCurrency(isFromField: isFromField),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.unfold_more,
                      color: Color(0xFFEC8116),
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    color: Color(0xFF4C4C4C),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    final children = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      children.add(Expanded(
        child: CalculatorButton(label: keys[i], onTap: () => _handleTap(keys[i])),
      ));
      if (i != keys.length - 1) children.add(const SizedBox(width: 12));
    }
    return Row(children: children);
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CalculatorButton(label: '0', wide: true, onTap: () => _handleTap('0')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CalculatorButton(label: '.', onTap: () => _handleTap('.')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CalculatorButton(label: '=', isEquals: true, onTap: () => _handleTap('=')),
        ),
      ],
    );
  }
}

/// Bottom sheet with a search field that filters the full currency list
/// live as you type — matches against both the code (e.g. "JPY") and the
/// full name (e.g. "Japanese yen").
class _CurrencyPickerSheet extends StatefulWidget {
  final Map<String, String> currencyNames;
  final String selectedCode;

  const _CurrencyPickerSheet({
    required this.currencyNames,
    required this.selectedCode,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, String>> get _filtered {
    final entries = widget.currencyNames.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (_query.isEmpty) return entries;
    final q = _query.toLowerCase();
    return entries
        .where((e) =>
            e.key.toLowerCase().contains(q) ||
            e.value.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFFEC8116),
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search currency or code…',
                    hintStyle: const TextStyle(color: Color(0xFF4C4C4C)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4C4C4C)),
                    filled: true,
                    fillColor: const Color(0xFF242424),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching currency',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final code = results[index].key;
                          final name = results[index].value;
                          final isSelected = code == widget.selectedCode;
                          return ListTile(
                            title: Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFEC8116)
                                    : Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              code,
                              style: const TextStyle(color: Color(0xFF4C4C4C)),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Color(0xFFEC8116))
                                : null,
                            onTap: () => Navigator.pop(context, code),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}