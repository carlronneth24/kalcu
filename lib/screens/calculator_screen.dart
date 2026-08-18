import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/calculator_button.dart';
import '../services/history_service.dart';
import 'history/history_screen.dart';


class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  double? _firstOperand;
  String? _pendingOperator;
  bool _shouldResetDisplay = false;

  // --- History tracking additions ---
  String _expression = '';
  bool _afterEquals = false;

  void _onDigitPressed(String digit) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display += digit;
      }

      if (_afterEquals) {
        _expression = digit;
        _afterEquals = false;
      } else if (_expression.isEmpty) {
        _expression = digit;
      } else {
        _expression += digit;
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }

      if (_afterEquals) {
        _expression = '0.';
        _afterEquals = false;
      } else if (!_expression.contains('.')) {
        _expression += '.';
      }
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      if (_pendingOperator != null && !_shouldResetDisplay) {
        _calculate();
      }
      _firstOperand = double.tryParse(_display);
      _pendingOperator = operator;
      _shouldResetDisplay = true;

      if (_afterEquals) {
        _expression = '$_display $operator ';
        _afterEquals = false;
      } else {
        _expression += ' $operator ';
      }
    });
  }

  void _calculate() {
    if (_firstOperand == null || _pendingOperator == null) return;
    final second = double.tryParse(_display) ?? 0;
    double result;
    switch (_pendingOperator) {
      case '+':
        result = _firstOperand! + second;
        break;
      case '-':
        result = _firstOperand! - second;
        break;
      case 'x':
        result = _firstOperand! * second;
        break;
      case '/':
        result = second == 0 ? double.nan : _firstOperand! / second;
        break;
      case '%':
        result = _firstOperand! % second;
        break;
      default:
        result = second;
    }
    _display = _formatResult(result);
    _pendingOperator = null;
    _firstOperand = null;
  }

  void _onEqualsPressed() {
    setState(() {
      final expressionToSave = _expression.trim();
      _calculate();
      _shouldResetDisplay = true;
      _afterEquals = true;

      // Only save if there was an actual expression (avoid saving a bare "0" tap)
      if (expressionToSave.isNotEmpty && expressionToSave.contains(' ')) {
        HistoryService.addEntry(expressionToSave, _display);
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _pendingOperator = null;
      _shouldResetDisplay = false;
      _expression = '';
      _afterEquals = false;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
      if (_expression.isNotEmpty && !_expression.endsWith(' ')) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  String _formatResult(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value.toString();
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
      case '=':
        _onEqualsPressed();
        break;
      case '.':
        _onDecimalPressed();
        break;
      case '+':
      case '-':
      case 'x':
      case '/':
      case '%':
        _onOperatorPressed(label);
        break;
      default:
        _onDigitPressed(label);
    }
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
              // Top bar: menu + history icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textWhite, size: 30),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppColors.textWhite, size: 30),
                    onPressed: _openHistory,
                  ),
                ],
              ),
              const Spacer(),
              // Display
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 64,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Button grid
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
