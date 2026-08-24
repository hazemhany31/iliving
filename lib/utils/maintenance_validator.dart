class MaintenanceValidator {
  /// Validates a maintenance ticket title.
  ///
  /// Requires:
  /// - Minimum 4 characters.
  /// - Maximum 80 characters.
  /// - Contains at least one alphabetical/letter word (Arabic or Latin).
  /// - Not composed of repeated/identical characters (e.g., 'aaaa', '\\\\\\\', '.....').
  /// - Character diversity (at least 3 unique non-whitespace characters).
  static String? validateTitle(String? value, {bool isAr = false}) {
    if (value == null || value.trim().isEmpty) {
      return isAr
          ? 'عنوان التذكرة مطلوب'
          : 'Ticket title is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 4) {
      return isAr
          ? 'عنوان التذكرة قصير جداً (4 أحرف على الأقل)'
          : 'Title is too short (min 4 characters)';
    }

    if (trimmed.length > 80) {
      return isAr
          ? 'عنوان التذكرة طويل جداً (الحد الأقصى 80 حرف)'
          : 'Title is too long (max 80 characters)';
    }

    // Check for repetitive/garbage characters (e.g. \\\\\\\, aaaaa, ....., 11111)
    if (_isRepetitiveGarbage(trimmed)) {
      return isAr
          ? 'يرجى إدخال عنوان مفهوم وتجنب تكرار الرموز أو الأحرف'
          : 'Please enter a meaningful title (avoid repeated characters/symbols)';
    }

    // Must contain letters (Arabic or Latin), not just symbols/numbers/punctuation
    if (!_containsMeaningfulWords(trimmed)) {
      return isAr
          ? 'يجب أن يحتوي العنوان على كلمات نصية واضحة'
          : 'Title must contain meaningful words (letters)';
    }

    return null;
  }

  /// Validates a maintenance ticket service description.
  ///
  /// Requires:
  /// - Minimum 10 characters.
  /// - Maximum 1000 characters.
  /// - Contains meaningful words (Arabic or Latin).
  /// - Not repetitive/garbage text.
  /// - At least 4 unique non-whitespace characters.
  static String? validateDescription(String? value, {bool isAr = false}) {
    if (value == null || value.trim().isEmpty) {
      return isAr
          ? 'وصف متطلبات الصيانة مطلوب'
          : 'Service description is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 10) {
      return isAr
          ? 'يرجى كتابة تفاصيل واضحة (10 أحرف على الأقل)'
          : 'Please provide clear details (min 10 characters)';
    }

    if (trimmed.length > 1000) {
      return isAr
          ? 'الوصف طويل جداً (الحد الأقصى 1000 حرف)'
          : 'Description is too long (max 1000 characters)';
    }

    // Check for repetitive garbage (e.g. \\\\\\\\\\\\, ..........., asdasdasd)
    if (_isRepetitiveGarbage(trimmed)) {
      return isAr
          ? 'النص غير مفهوم. يرجى توضيح العطل أو الخدمة المطلوبة'
          : 'Meaningless text. Please describe the required service clearly';
    }

    // Check for symbol-only or punctuation-only spam
    if (!_containsMeaningfulWords(trimmed)) {
      return isAr
          ? 'يجب أن يحتوي الوصف على كلمات مفهومة تشرح المشكلة'
          : 'Description must contain meaningful descriptive text';
    }

    return null;
  }

  /// Detects if text is repetitive garbage (e.g., \\\\\\\, aaaaa, ....., 111111, abcabcabc)
  static bool _isRepetitiveGarbage(String text) {
    final sanitized = text.replaceAll(RegExp(r'\s+'), '');
    if (sanitized.isEmpty) return true;

    // Check unique character count
    final uniqueChars = sanitized.split('').toSet();
    if (sanitized.length >= 4 && uniqueChars.length <= 2) {
      return true;
    }

    // Check if it's purely repeated symbols / punctuation
    final symbolPattern = RegExp(r'^[\W_]+$');
    if (symbolPattern.hasMatch(sanitized)) {
      return true;
    }

    // Check for identical consecutive characters covering >= 60% of length
    final maxConsecutive = _maxConsecutiveSameChar(sanitized);
    if (sanitized.length >= 5 && maxConsecutive / sanitized.length > 0.5) {
      return true;
    }

    return false;
  }

  /// Checks whether text contains alphabetical letters (Arabic or Latin)
  static bool _containsMeaningfulWords(String text) {
    // Matches Arabic unicode range \u0600-\u06FF or Latin letters a-zA-Z
    final letterRegex = RegExp(r'[\u0600-\u06FFa-zA-Z]{2,}');
    return letterRegex.hasMatch(text);
  }

  static int _maxConsecutiveSameChar(String s) {
    if (s.isEmpty) return 0;
    int maxRun = 1;
    int currentRun = 1;
    for (int i = 1; i < s.length; i++) {
      if (s[i] == s[i - 1]) {
        currentRun++;
        if (currentRun > maxRun) maxRun = currentRun;
      } else {
        currentRun = 1;
      }
    }
    return maxRun;
  }
}
