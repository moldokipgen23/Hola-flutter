import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static const String prefKey = 'app_language';

  static const Map<String, String> _languages = {
    'en': 'English',
    'hi': 'हिन्दी',
    'mni': 'মৈতৈলোন্',
    'lus': 'Mizo ṭawng',
    'hmr': 'Harlem dawng',
  };

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_name': 'Eiho One',
      'explore': 'Explore',
      'shop': 'Shop',
      'book_me': 'Book Me',
      'saved': 'Saved',
      'profile': 'Profile',
      'search': 'Search',
      'categories': 'Categories',
      'settings': 'Settings',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'logout': 'Logout',
      'login': 'Login',
      'no_results': 'No results found',
      'retry': 'Retry',
      'loading': 'Loading...',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm': 'Confirm',
    },
    'hi': {
      'app_name': 'होला',
      'explore': 'खोजें',
      'shop': 'खरीदारी',
      'book_me': 'बुक करें',
      'saved': 'सुरक्षित',
      'profile': 'प्रोफ़ाइल',
      'search': 'खोज',
      'categories': 'श्रेणियाँ',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'dark_mode': 'डार्क मोड',
      'logout': 'लॉग आउट',
      'login': 'लॉग इन',
      'no_results': 'कोई परिणाम नहीं मिला',
      'retry': 'पुनः प्रयास',
      'loading': 'लोड हो रहा है...',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'delete': 'हटाएं',
      'edit': 'संपादित',
      'confirm': 'पुष्टि',
    },
    'mni': {
      'app_name': 'হোলা',
      'explore': 'খোঁজো',
      'shop': 'শেল',
      'book_me': 'বুক তাও',
      'saved': 'সেম্বা',
      'profile': 'প্ৰফাইল',
      'search': 'খোঁজ',
      'categories': 'কেতেগোৰী',
      'settings': 'সেটিং',
      'language': 'লোন',
      'dark_mode': 'মতুং মোদ',
      'logout': 'লগ আউট',
      'login': 'লগ ইন',
      'no_results': 'ফল ওইদে',
      'retry': 'তৈগিদোম',
      'loading': 'লোদ তাওরি...',
      'cancel': 'শেল তাও',
      'save': 'সেম্বা',
      'delete': 'মুত্ৰ',
      'edit': 'সিক্সিদো',
      'confirm': 'পক্ষ্বিং',
    },
    'lus': {
      'app_name': 'Eiho One',
      'explore': 'Fiangnawh',
      'shop': 'Zin',
      'book_me': 'Book rawh',
      'saved': 'Siam thei',
      'profile': 'Profile',
      'search': 'Zawn',
      'categories': 'Dan',
      'settings': 'Settings',
      'language': 'Tawng',
      'dark_mode': 'Dark Mode',
      'logout': 'Tawh lut',
      'login': 'Lut',
      'no_results': 'A thleng em',
      'retry': 'Dawn leh',
      'loading': 'Load...',
      'cancel': 'Tawh',
      'save': 'Siam',
      'delete': 'Vut',
      'edit': 'Sik',
      'confirm': 'P鞔',
    },
    'hmr': {
      'app_name': 'Eiho One',
      'explore': 'Khoj',
      'shop': 'Shil',
      'book_me': 'Book ka',
      'saved': 'Sem ka',
      'profile': 'Profile',
      'search': 'Khoj',
      'categories': 'Dan',
      'settings': 'Settings',
      'language': 'Da',
      'dark_mode': 'Mun dim',
      'logout': 'Tawh lut',
      'login': 'Lut',
      'no_results': 'Amah hle',
      'retry': 'Dawn le',
      'loading': 'Load...',
      'cancel': 'Tawh',
      'save': 'Sem',
      'delete': 'Vut',
      'edit': 'Sik',
      'confirm': 'P鞔',
    },
  };

  static String getString(String key, [String langCode = 'en']) {
    return _strings[langCode]?[key] ?? _strings['en']?[key] ?? key;
  }

  static Map<String, String> get languages => Map.from(_languages);

  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefKey) ?? 'en';
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, code);
  }

  static String getNativeName(String code) => _languages[code] ?? code;
}
