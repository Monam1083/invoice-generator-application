/// Supported currencies for invoicing, mapping a currency code to its symbol.
class CurrencyUtils {
  CurrencyUtils._();

  static const Map<String, String> currencies = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'PKR': 'Rs',
    'INR': '₹',
    'AED': 'AED',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  static String symbolFor(String code) => currencies[code] ?? '\$';

  static String format(double amount, String symbol) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
