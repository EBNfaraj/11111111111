class NumberToWords {
  static const List<String> units = [
    '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة'
  ];

  static const List<String> teens = [
    'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'
  ];

  static const List<String> tens = [
    '', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'
  ];

  static const List<String> hundreds = [
    '', 'مائة', 'مائتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة'
  ];

  static String convert(int number) {
    if (number == 0) return 'صفر';
    if (number < 0) return 'سالب ' + convert(number.abs());

    String result = '';

    if (number >= 1000000) {
      int millions = number ~/ 1000000;
      if (millions == 1) {
        result += 'مليون ';
      } else if (millions == 2) {
        result += 'مليونان ';
      } else if (millions <= 10) {
        result += '${_convertUnder1000(millions)} ملايين ';
      } else {
        result += '${_convertUnder1000(millions)} مليون ';
      }
      number %= 1000000;
      if (number > 0) result += 'و';
    }

    if (number >= 1000) {
      int thousands = number ~/ 1000;
      if (thousands == 1) {
        result += 'ألف ';
      } else if (thousands == 2) {
        result += 'ألفان ';
      } else if (thousands <= 10) {
        result += '${_convertUnder1000(thousands)} آلاف ';
      } else {
        result += '${_convertUnder1000(thousands)} ألف ';
      }
      number %= 1000;
      if (number > 0) result += 'و';
    }

    if (number > 0) {
      result += _convertUnder1000(number);
    }

    return result.trim();
  }

  static String _convertUnder1000(int n) {
    String res = '';
    if (n >= 100) {
      res += '${hundreds[n ~/ 100]} ';
      n %= 100;
      if (n > 0) res += 'و';
    }

    if (n >= 20) {
      if (n % 10 > 0) {
        res += '${units[n % 10]} و${tens[n ~/ 10]}';
      } else {
        res += tens[n ~/ 10];
      }
    } else if (n >= 10) {
      res += teens[n - 10];
    } else if (n > 0) {
      res += units[n];
    }

    return res.trim();
  }

  static String convertWithCurrency(double amount) {
    int whole = amount.floor();
    int decimal = ((amount - whole) * 100).round();
    
    String result = convert(whole) + ' ريال يمني';
    if (decimal > 0) {
      result += ' و ' + convert(decimal) + ' فلس';
    }
    return result;
  }
}
