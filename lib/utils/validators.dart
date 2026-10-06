class Validators {
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a brief description of the symptoms';
    }
    if (value.trim().length > 300) {
      return 'Description cannot exceed 300 characters';
    }
    return null;
  }
}
