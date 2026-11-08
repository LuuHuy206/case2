class AppValidators {
  static String? validateRequired(String? value, [String fieldName = 'Trường này']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+\$');
    if (!regex.hasMatch(value.trim())) {
      return 'Định dạng email không hợp lệ';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    return null;
  }
}
