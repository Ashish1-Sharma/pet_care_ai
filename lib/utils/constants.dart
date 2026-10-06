class AppConstants {
  static const List<String> petTypes = [
    'Dog',
    'Cat',
    'Rabbit',
    'Bird',
    'Cow',
    'Horse',
    'Other',
  ];

  static const List<String> bodyParts = [
    'Skin',
    'Eye',
    'Ear',
    'Paw',
    'Mouth',
    'Nose',
    'Leg',
    'Other',
  ];

  static const List<String> symptomsList = [
    'Itching',
    'Hair Loss',
    'Redness',
    'Swelling',
    'Limping',
    'Vomiting',
    'Diarrhea',
    'Lethargy',
    'Coughing',
    'Sneezing',
    'Loss of Appetite',
    'Increased Thirst',
    'Frequent Urination',
    'Constipation',
    'Bad Breath',
    'Drooling',
    'Shivering',
    'Breathing Difficulty',
    'Eye or Nose Discharge',
    'Behavioral Change',
    'Scratching',
    'Blood in Urine/Stool',
    'Seizures',
    'Lumps or Bumps',
  ];

  static const List<Map<String, dynamic>> scanPackages = [
    {
      'title': 'Starter',
      'price': 5,
      'scans': 5,
    },
    {
      'title': 'Popular',
      'price': 20,
      'scans': 25,
    },
    {
      'title': 'Premium',
      'price': 49,
      'scans': 75,
    },
    {
      'title': 'Unlimited',
      'price': 99,
      'scans': 200,
    },
  ];
}
