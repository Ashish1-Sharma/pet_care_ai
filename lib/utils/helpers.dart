class Helpers {
  static String formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final year = dateTime.year;
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      return '$day/$month/$year';
    } catch (_) {
      return dateString;
    }
  }

  static String getFriendlyErrorMessage(dynamic error) {
    // Basic fallback error messages
    return 'Something went wrong. Please try again later.';
  }

  static String mapSymptomToSlug(String display) {
    switch (display) {
      case 'Itching': return 'itching';
      case 'Hair Loss': return 'hair_loss';
      case 'Redness': return 'redness';
      case 'Swelling': return 'swelling';
      case 'Limping': return 'limping';
      case 'Vomiting': return 'vomiting';
      case 'Diarrhea': return 'diarrhea';
      case 'Lethargy': return 'lethargy';
      case 'Coughing': return 'coughing';
      case 'Sneezing': return 'sneezing';
      case 'Loss of Appetite': return 'loss_of_appetite';
      case 'Increased Thirst': return 'increased_thirst';
      case 'Frequent Urination': return 'frequent_urination';
      case 'Constipation': return 'constipation';
      case 'Bad Breath': return 'bad_breath';
      case 'Drooling': return 'drooling';
      case 'Shivering': return 'shivering';
      case 'Breathing Difficulty': return 'breathing_difficulty';
      case 'Eye or Nose Discharge': return 'discharge_eye_nose';
      case 'Behavioral Change': return 'behavioral_change';
      case 'Scratching': return 'scratching';
      case 'Blood in Urine/Stool': return 'blood_in_urine_stool';
      case 'Seizures': return 'seizures';
      case 'Lumps or Bumps': return 'lump_bump';
      default: return display.toLowerCase().replaceAll(' ', '_');
    }
  }

  static String mapSlugToSymptom(String slug) {
    switch (slug) {
      case 'itching': return 'Itching';
      case 'hair_loss': return 'Hair Loss';
      case 'redness': return 'Redness';
      case 'swelling': return 'Swelling';
      case 'limping': return 'Limping';
      case 'vomiting': return 'Vomiting';
      case 'diarrhea': return 'Diarrhea';
      case 'lethargy': return 'Lethargy';
      case 'coughing': return 'Coughing';
      case 'sneezing': return 'Sneezing';
      case 'loss_of_appetite': return 'Loss of Appetite';
      case 'increased_thirst': return 'Increased Thirst';
      case 'frequent_urination': return 'Frequent Urination';
      case 'constipation': return 'Constipation';
      case 'bad_breath': return 'Bad Breath';
      case 'drooling': return 'Drooling';
      case 'shivering': return 'Shivering';
      case 'breathing_difficulty': return 'Breathing Difficulty';
      case 'discharge_eye_nose': return 'Eye or Nose Discharge';
      case 'behavioral_change': return 'Behavioral Change';
      case 'scratching': return 'Scratching';
      case 'blood_in_urine_stool': return 'Blood in Urine/Stool';
      case 'seizures': return 'Seizures';
      case 'lump_bump': return 'Lumps or Bumps';
      default: return slug;
    }
  }
}
