class MoneyUtils {
  static double rate = 25000; // 1 USD = 25,000 VND

  static String format(int amount, String currency) {
    if (currency == "USD") {
      double usd = amount / rate;
      return "\$" + usd.toStringAsFixed(2);
    } else {
      return amount.toString() + " VND";
    }
  }
}