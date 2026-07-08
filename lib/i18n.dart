class I18n {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'Hola',
      'home': 'Home',
      'search': 'Search',
      'categories': 'Categories',
      'saved': 'Saved',
      'profile': 'Profile',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'no_results': 'No results found',
      'loading': 'Loading...',
      'error': 'Something went wrong',
    },
    'mni': {
      'app_name': 'Hola',
      'home': 'Yum',
      'search': 'Thijin',
      'categories': 'Maong',
      'saved': 'Thakhiba',
      'profile': 'Meeram',
      'login': 'Changmin',
      'register': 'Yaopham',
      'logout': 'Thokthok',
      'no_results': 'Ama yaodri',
      'loading': 'Pungningai...',
      'error': 'Awatpa oikhre',
    },
  };

  static String get(String key, {String locale = 'en'}) {
    return _translations[locale]?[key] ?? _translations['en']?[key] ?? key;
  }
}
