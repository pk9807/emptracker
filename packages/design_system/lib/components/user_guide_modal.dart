import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_spacing.dart';
import 'depth_card.dart';

enum UserGuideLanguage {
  english,
  hindi,
  hinglish,
  nepali,
  marathi,
  bengali,
  tamil,
}

class UserGuideModal extends StatefulWidget {
  final bool isAdmin;
  final UserGuideLanguage initialLanguage;

  const UserGuideModal({
    super.key,
    required this.isAdmin,
    this.initialLanguage = UserGuideLanguage.hinglish,
  });

  static Future<void> show(BuildContext context, {required bool isAdmin}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserGuideModal(isAdmin: isAdmin),
    );
  }

  @override
  State<UserGuideModal> createState() => _UserGuideModalState();
}

class _UserGuideModalState extends State<UserGuideModal> with SingleTickerProviderStateMixin {
  late UserGuideLanguage _selectedLang;
  late bool _isAdminView;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.initialLanguage;
    _isAdminView = widget.isAdmin;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getLanguageLabel(UserGuideLanguage lang) {
    switch (lang) {
      case UserGuideLanguage.english:
        return 'English 🇬🇧';
      case UserGuideLanguage.hindi:
        return 'हिंदी 🇮🇳';
      case UserGuideLanguage.hinglish:
        return 'Hinglish 🇮🇳';
      case UserGuideLanguage.nepali:
        return 'नेपाली 🇳🇵';
      case UserGuideLanguage.marathi:
        return 'मराठी 🇮🇳';
      case UserGuideLanguage.bengali:
        return 'বাংলা 🇮🇳';
      case UserGuideLanguage.tamil:
        return 'தமிழ் 🇮🇳';
    }
  }

  List<Map<String, dynamic>> _getAdminSteps() {
    switch (_selectedLang) {
      case UserGuideLanguage.hindi:
        return [
          {
            'icon': Icons.radar_rounded,
            'title': '1. लाइव 3D रडार और कर्मचारी ट्रैकिंग',
            'desc': 'मैप पर सभी फील्ड कर्मचारियों की लाइव लोकेशन, स्पीड (km/h) और फोन बैटरी % रियल-टाइम में देखें। किसी भी कर्मचारी पर क्लिक करके उनका आज का पूरा रूट पाथ देख सकते हैं।',
            'tip': '💡 टिप: "OpenStreetMap" या "Google Maps" स्विच करने के लिए टॉप-लेफ्ट बटन का उपयोग करें।',
          },
          {
            'icon': Icons.storefront_rounded,
            'title': '2. दुकानें और जिओफेंस (Geofence) सेटअप',
            'desc': 'नई दुकान या क्लाइंट लोकेशन रजिस्टर करें और 100m से 500m का जिओफेंस रेडियस सेट करें ताकि कर्मचारी केवल सही जगह पर ही चेक-इन कर सकें।',
            'tip': '💡 टिप: मैप पर पिन ड्रैग करके या सर्च बार में दुकान का नाम लिखकर सीधे लोकेशन सेट करें।',
          },
          {
            'icon': Icons.directions_rounded,
            'title': '3. गूगल मैप्स स्टाइल प्लेस इंटेलिजेंस और 1-क्लिक डिस्पैच',
            'desc': 'सर्च बार में "Workout Gym Kanpur" जैसे नाम खोजें। Google Maps प्लेस कार्ड से सीधे "Directions" देखें और "Send to phone" दबाकर कर्मचारी के मोबाइल पर असाइन करें।',
            'tip': '💡 टिप: 5 एक्शन बटन (Directions, Save, Nearby, Send to phone, Share) तुरंत काम करते हैं।',
          },
          {
            'icon': Icons.verified_user_rounded,
            'title': '4. विजिट और फोटो प्रूफ ऑडिट',
            'desc': 'कर्मचारियों द्वारा खींची गई लाइव स्टोर फोटो, टाइमस्टैम्प, और GPS दूरी की सत्यता की जांच करें। फर्जी विजिट तुरंत लाल रंग में हाइलाइट होती हैं।',
            'tip': '💡 टिप: फोटो पर क्लिक करके फुल-स्क्रीन HD फोटो और डिजिटल हस्ताक्षर देखें।',
          },
          {
            'icon': Icons.analytics_rounded,
            'title': '5. उपस्थिति और रिपोर्ट एक्सपोर्ट',
            'desc': 'दैनिक किलोमीटर यात्रा, कुल कार्य घंटे और उपस्थिति का पूरा डेटा 1-क्लिक में Excel या PDF में डाउनलोड करें।',
            'tip': '💡 टिप: फ़िल्टर लगाकर महीने या विशेष कर्मचारी की रिपोर्ट तैयार करें।',
          },
        ];

      case UserGuideLanguage.nepali:
        return [
          {
            'icon': Icons.radar_rounded,
            'title': '१. प्रत्यक्ष ३डी रडार र कर्मचारी ट्र्याकिङ',
            'desc': 'नक्सामा सबै कर्मचारीहरूको प्रत्यक्ष स्थान, गति (km/h) र ब्याट्री % हेर्नुहोस्। कर्मचारीमा क्लिक गरेर आजको सम्पूर्ण यात्रा मार्ग हेर्न सकिन्छ।',
            'tip': '💡 सुझाव: "OpenStreetMap" वा "Google Maps" स्विच गर्न माथिल्लो बायाँ बटन प्रयोग गर्नुहोस्।',
          },
          {
            'icon': Icons.storefront_rounded,
            'title': '२. पसल र जियोफेन्स (Geofence) दर्ता',
            'desc': 'नयाँ पसल वा ग्राहक स्थान दर्ता गर्नुहोस् र १०० मिटरको परिधि सेट गर्नुहोस् ताकि कर्मचारीले सही स्थानमा मात्र चेक-इन गर्न सकून्।',
            'tip': '💡 सुझाव: नक्सामा सिधै स्थान खोज्न सर्च बार प्रयोग गर्नुहोस्।',
          },
          {
            'icon': Icons.directions_rounded,
            'title': '३. गुगल नक्सा शैली र १-क्लिक पठाउने सुविधा',
            'desc': 'कुनै पनि पसल खोज्नुहोस् र "Send to phone" थिचेर कर्मचारीको मोबाइलमा सिधै असाइन गर्नुहोस्।',
            'tip': '💡 सुझाव: दिशा निर्देश (Directions) ले तत्काल छोटो बाटो देखाउँछ।',
          },
          {
            'icon': Icons.verified_user_rounded,
            'title': '४. भ्रमण र फोटो प्रमाण अडिट',
            'desc': 'कर्मचारीले खिचेको पसलको प्रत्यक्ष फोटो, समय र GPS दूरी प्रमाणित गर्नुहोस्।',
            'tip': '💡 सुझाव: गलत भ्रमणहरू तत्काल रातो रङमा देखिन्छन्।',
          },
          {
            'icon': Icons.analytics_rounded,
            'title': '५. हाजिरी र रिपोर्ट डाउनलोड',
            'desc': 'दैनिक यात्रा गरेको किलोमिटर, काम गरेको घण्टा र हाजिरी रिपोर्ट Excel वा PDF मा डाउनलोड गर्नुहोस्।',
            'tip': '💡 सुझाव: महिना वा कर्मचारी अनुसार फिल्टर गर्नुहोस्।',
          },
        ];

      case UserGuideLanguage.marathi:
        return [
          {
            'icon': Icons.radar_rounded,
            'title': '१. लाइव्ह ३डी रडार आणि कर्मचारी ट्रॅकिंग',
            'desc': 'नकाशावर सर्व कर्मचाऱ्यांचे थेट लोकेशन, वेग (km/h) आणि बॅटरी % पहा. कर्मचाऱ्यावर क्लिक करून आजचा संपूर्ण प्रवास मार्ग तपासा.',
            'tip': '💡 टिप: टॉप-लेफ्ट बटणावरून नकाशे स्विच करा.',
          },
          {
            'icon': Icons.storefront_rounded,
            'title': '२. दुकाने आणि जिओफेन्स सेटअप',
            'desc': 'नवीन दुकान जोडा आणि १०० मी. चा जिओफेन्स ठेवा जेणेकरून कर्मचारी योग्य ठिकाणीच हजेरी लावतील.',
            'tip': '💡 टिप: नकाशावर शोधून थेट लोकेशन पिन करा.',
          },
          {
            'icon': Icons.directions_rounded,
            'title': '३. १-क्लिक द्वारे कर्मचाऱ्याला पाठवणे',
            'desc': 'दुकान निवडून "Send to phone" द्वारे थेट कर्मचाऱ्याच्या फोनवर टास्क पाठवा.',
            'tip': '💡 टिप: Directions बटणाने तात्काळ मार्ग दिसतो.',
          },
          {
            'icon': Icons.verified_user_rounded,
            'title': '४. व्हिजिट फोटो ऑडिट',
            'desc': 'कर्मचाऱ्याने काढलेला दुकानाचा फोटो, GPS लोकेशन आणि वेळेची खात्री करा.',
            'tip': '💡 टिप: बनावट व्हिजिट लगेच लाल रंगात ओळखता येतात.',
          },
          {
            'icon': Icons.analytics_rounded,
            'title': '५. हजेरी व रिपोर्ट्स डाउनलोड',
            'desc': 'दररोजचा प्रवास अंतर, उपस्थिती आणि वेळ एक्सेल/पीडीएफ मध्ये सेव्ह करा.',
            'tip': '💡 टिप: १-क्लिक मध्ये संपूर्ण महिन्याचा डेटा मिळवा.',
          },
        ];

      case UserGuideLanguage.bengali:
        return [
          {
            'icon': Icons.radar_rounded,
            'title': '১. লাইভ ৩ডি ট্র্যাকিং ও কর্মচারী নজরদারি',
            'desc': 'ম্যাপে সকল কর্মচারীর রিয়েল-টাইম লোকেশন, গতি এবং ব্যাটারি শতাংশ দেখুন। কর্মচারীতে ক্লিক করে তাদের পুরো দিনের রুট দেখুন।',
            'tip': '💡 টিপস: উপরের বাম বাটন দিয়ে ম্যাপ টাইপ পরিবর্তন করুন।',
          },
          {
            'icon': Icons.storefront_rounded,
            'title': '২. দোকান ও জিওফেন্সিং (Geofence) সেটআপ',
            'desc': 'নতুন দোকান বা গ্রাহকের লোকেশন যুক্ত করুন এবং ১০০ মিটারের জিওফেন্স সেট করুন।',
            'tip': '💡 টিপস: সার্চ বারে সার্চ করে সহজেই পিন করুন।',
          },
          {
            'icon': Icons.directions_rounded,
            'title': '৩. সরাসরি মোবাইলে অ্যাসাইন (Send to Phone)',
            'desc': 'যেকোনো দোকান নির্বাচন করে ১-ক্লিকে কর্মচারীর ফোনে পাঠিয়ে দিন।',
            'tip': '💡 টিপস: Directions বাটনে ক্লিক করে রুট দেখুন।',
          },
          {
            'icon': Icons.verified_user_rounded,
            'title': '৪. ভিজিট ও ফটো প্রুফ অডিট',
            'desc': 'লাইভ স্টোর ফটো, টাইমস্ট্যাম্প এবং দূরত্বের নির্ভুলতা যাচাই করুন।',
            'tip': '💡 টিপস: ফেক ভিজিট তাৎক্ষণিক লাল রঙে চিহ্নিত হবে।',
          },
          {
            'icon': Icons.analytics_rounded,
            'title': '৫. উপস্থিতি ও রিপোর্ট ডাউনলোড',
            'desc': 'প্রতিদিনের ভ্রমণ দূরত্ব ও উপস্থিতি Excel/PDF ফাইলে ডাউনলোড করুন।',
            'tip': '💡 টিপস: মাসভিত্তিক রিপোর্ট খুব সহজেই পাওয়া যায়।',
          },
        ];

      case UserGuideLanguage.tamil:
        return [
          {
            'icon': Icons.radar_rounded,
            'title': '1. நேரலை 3D கண்காணிப்பு (Live Tracking)',
            'desc': 'வரைபடத்தில் களப்பணியாளர்களின் நேரலை இருப்பிடம், வேகம் மற்றும் பேட்டரி சதவீதத்தை உடனடியாகக் கண்காணிக்கலாம்.',
            'tip': '💡 குறிப்பு: ஊழியரின் முழு வழித்தடத்தையும் ஒரே கிளிக்கில் பார்க்கலாம்.',
          },
          {
            'icon': Icons.storefront_rounded,
            'title': '2. கடைகள் மற்றும் ஜியோஃபென்ஸ் (Geofence)',
            'desc': 'புதிய கடைகளை வரைபடத்தில் பதிவு செய்து 100m வரம்பை அமைக்கவும்.',
            'tip': '💡 குறிப்பு: ஊழியர்கள் சரியான இடத்தில் இருப்பதை உறுதி செய்கிறது.',
          },
          {
            'icon': Icons.directions_rounded,
            'title': '3. போனுக்கு அனுப்பும் வசதி (Send to Phone)',
            'desc': 'தேர்ந்தெடுக்கப்பட்ட கடையை ஊழியரின் மொபைலுக்கு நேரடியாக அனுப்பலாம்.',
            'tip': '💡 குறிப்பு: Directions பட்டன் உடனடி வழியைக் காட்டும்.',
          },
          {
            'icon': Icons.verified_user_rounded,
            'title': '4. விசிட் மற்றும் புகைப்பட சரிபார்ப்பு',
            'desc': 'ஊழியர் எடுத்த கடை புகைப்படம் மற்றும் நேர முத்திரையை ஆய்வு செய்யவும்.',
            'tip': '💡 குறிப்பு: போலி வருகைகளை எளிதில் கண்டறியலாம்.',
          },
          {
            'icon': Icons.analytics_rounded,
            'title': '5. வருகை மற்றும் அறிக்கைகள்',
            'desc': 'தினசரி பயணம் மற்றும் வருகை அறிக்கையை Excel அல்லது PDF வடிவில் பதிவிறக்கவும்.',
            'tip': '💡 குறிப்பு: மாதாந்திர அறிக்கைகள் மிக விரைவாகத் தயாராகும்.',
          },
        ];

      case UserGuideLanguage.english:
        return [
          {
            'icon': Icons.radar_rounded,
            'title': '1. Live 3D Radar & Employee Telemetry',
            'desc': 'Monitor all on-ground field executives in real-time with GPS speed (km/h), connectivity status, and battery percentage. Tap on any employee card to inspect their turn-by-turn route history.',
            'tip': '💡 Pro Tip: Toggle between "OpenStreetMap (Free)" and "Google Maps" at the top left.',
          },
          {
            'icon': Icons.storefront_rounded,
            'title': '2. Shop Directory & Geofence Boundaries',
            'desc': 'Register new shops, dealer outlets, or client offices. Configure custom geofence radii (e.g. 100m – 500m) to ensure executives are physically on-site before checking in.',
            'tip': '💡 Pro Tip: Drag the map pin or type in the search bar for instant coordinate snapping.',
          },
          {
            'icon': Icons.directions_rounded,
            'title': '3. Google Maps Place Intelligence & 1-Click Dispatch',
            'desc': 'Search places like "Workout Gym Kanpur". Review reviews, opening hours, dual-language titles, and press "Send to phone" to dispatch the client directly to a field agent.',
            'tip': '💡 Pro Tip: 5 interactive action buttons: Directions, Save, Nearby, Send to phone, and Share.',
          },
          {
            'icon': Icons.verified_user_rounded,
            'title': '4. Visit Proof & Photo Audits',
            'desc': 'Verify live storefront photos, GPS timestamps, and distance deviation. The system automatically highlights fake visits in red if outside the allowed geofence.',
            'tip': '💡 Pro Tip: Tap any thumbnail to view full-resolution photos and digital signatures.',
          },
          {
            'icon': Icons.analytics_rounded,
            'title': '5. Attendance Analytics & Export Reports',
            'desc': 'Analyze total kilometers traveled, active vs idle duty hours, and export audit-ready reports directly to Excel and PDF.',
            'tip': '💡 Pro Tip: Filter by date range or specific employee for swift monthly payroll reviews.',
          },
        ];

      case UserGuideLanguage.hinglish:
      default:
        return [
          {
            'icon': Icons.radar_rounded,
            'title': '1. Live 3D Radar aur Employee Tracking',
            'desc': 'Map par sabhi field employees ki real-time location, speed (km/h), aur phone battery % dekhein. Kisi bhi employee par click karke unka aaj ka turn-by-turn travel route dekh sakte hain.',
            'tip': '💡 Pro Tip: Top-left button se "OpenStreetMap" ya "Google Maps" switch kar sakte hain.',
          },
          {
            'icon': Icons.storefront_rounded,
            'title': '2. Shops aur Geofence Setup',
            'desc': 'Nayi shop ya client location add karein aur 100m ka geofence radius set karein taaki employee sirf physical presence me hi check-in kar sake.',
            'tip': '💡 Pro Tip: Search bar me shop name type karke instant pin locate karein.',
          },
          {
            'icon': Icons.directions_rounded,
            'title': '3. Google Maps Place Details & 1-Click Dispatch',
            'desc': '"Workout Gym Kanpur" jaise shops search karein. Card me se "Directions" route dekhein aur "Send to phone" button daba kar field employee ke phone par assign karein.',
            'tip': '💡 Pro Tip: 5 action buttons (Directions, Save, Nearby, Send to phone, Share) 100% active hain.',
          },
          {
            'icon': Icons.verified_user_rounded,
            'title': '4. Visit Proof aur Photo Audit',
            'desc': 'Field agent dwara li gayi live store photo, timestamp aur GPS accuracy verify karein. Fake visits auto red highlight ho jati hain.',
            'tip': '💡 Pro Tip: Photo par tap karke full HD photo aur signature check karein.',
          },
          {
            'icon': Icons.analytics_rounded,
            'title': '5. Attendance Analytics aur Report Export',
            'desc': 'Daily travel distance (km), active hours aur attendance sheet 1-click me Excel ya PDF me export karein.',
            'tip': '💡 Pro Tip: Date range filter laga kar monthly payroll fast generate karein.',
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getEmployeeSteps() {
    switch (_selectedLang) {
      case UserGuideLanguage.hindi:
        return [
          {
            'icon': Icons.camera_alt_rounded,
            'title': '1. जीपीएस + सेल्फी हाजिरी (Punch-In)',
            'desc': 'सुबह ऐप खोलें। आपकी लोकेशन अपने आप सत्यापित होगी। एक लाइव सेल्फी लें और "Punch In" बटन दबाएं। आपकी ड्यूटी शुरू हो जाएगी।',
            'tip': '💡 टिप: ड्यूटी के दौरान लोकेशन परमिशन को "Always Allow" रखें।',
          },
          {
            'icon': Icons.near_me_rounded,
            'title': '2. नजदीकी दुकानों की लिस्ट (Nearest First)',
            'desc': 'ऐप आपके सबसे करीब स्थित दुकानों को सबसे ऊपर दिखाता है ताकि आपका पेट्रोल और समय दोनों बच सकें।',
            'tip': '💡 टिप: दुकान पर टैप करके फोन नंबर और संपर्क व्यक्ति देखें।',
          },
          {
            'icon': Icons.navigation_rounded,
            'title': '3. 1-टैप टर्न-बाय-टर्न नेविगेशन',
            'desc': 'दुकान कार्ड पर "Navigate" दबाएं। मैप आपको दुकान तक पहुंचने का सबसे छोटा और आसान रास्ता दिखाएगा।',
            'tip': '💡 टिप: इन-ऐप गूगल मैप्स या ओएसआरएम रूटिंग का आनंद लें।',
          },
          {
            'icon': Icons.check_circle_rounded,
            'title': '4. दुकान के अंदर चेक-इन और फोटो प्रूफ',
            'desc': 'जैसे ही आप दुकान के 100 मीटर के दायरे में पहुंचेंगे, चेक-इन बटन हरा हो जाएगा। दुकान का फोटो लें और विजिट सबमिट करें।',
            'tip': '💡 टिप: दुकान मालिक के डिजिटल हस्ताक्षर भी जोड़ सकते हैं।',
          },
          {
            'icon': Icons.wifi_off_rounded,
            'title': '5. ऑफलाइन मोड और ऑटो-सिंक',
            'desc': 'यदि बेसमेंट या गांव में इंटरनेट नहीं है, तो भी ऐप सामान्य रूप से काम करता है। इंटरनेट आने पर डेटा अपने आप सर्वर पर सिंक हो जाएगा।',
            'tip': '💡 टिप: डेटा खोने का कोई डर नहीं है।',
          },
        ];

      case UserGuideLanguage.nepali:
        return [
          {
            'icon': Icons.camera_alt_rounded,
            'title': '१. जीपीएस + सेल्फी हाजिरी (Punch-In)',
            'desc': 'बिहान एप खोल्नुहोस्। स्थान प्रमाणित भएपछि सेल्फी खिचेर "Punch In" थिच्नुहोस्।',
            'tip': '💡 सुझाव: लोकेशन सधैं चालु राख्नुहोस्।',
          },
          {
            'icon': Icons.near_me_rounded,
            'title': '२. नजिकका पसलहरूको सूची',
            'desc': 'एपले तपाईंको सबैभन्दा नजिक रहेका पसलहरूलाई पहिले देखाउँछ।',
            'tip': '💡 सुझाव: इन्धन र समय बचत गर्नुहोस्।',
          },
          {
            'icon': Icons.navigation_rounded,
            'title': '३. १-ट्याप बाटो निर्देशन (Navigation)',
            'desc': '"Navigate" थिचेर पसलसम्म पुग्ने सबैभन्दा छोटो बाटो हेर्नुहोस्।',
            'tip': '💡 सुझाव: सिधै एप भित्रै बाटो देखिन्छ।',
          },
          {
            'icon': Icons.check_circle_rounded,
            'title': '४. चेक-इन र फोटो प्रमाण पेश गर्ने',
            'desc': 'पसलको १०० मिटर नजिक पुगेपछि चेक-इन बटन हरियो हुन्छ। फोटो खिचेर सबमिट गर्नुहोस्।',
            'tip': '💡 सुझाव: ग्राहकको हस्ताक्षर पनि लिन सकिन्छ।',
          },
          {
            'icon': Icons.wifi_off_rounded,
            'title': '५. इन्टरनेट बिना (Offline) काम गर्ने',
            'desc': 'इन्टरनेट नभएको ठाउँमा पनि एप चल्छ र इन्टरनेट आएपछि स्वतः सिंक हुन्छ।',
            'tip': '💡 सुझाव: कुनै पनि डेटा हराउँदैन।',
          },
        ];

      case UserGuideLanguage.marathi:
        return [
          {
            'icon': Icons.camera_alt_rounded,
            'title': '१. सेल्फी + GPS हजेरी (Punch-In)',
            'desc': 'सकाळी ॲप उघडा, सेल्फी काढा आणि Punch In बटण दाबा. तुमची ड्युटी सुरू होईल.',
            'tip': '💡 टिप: लोकेशन परमिशन चालू ठेवा.',
          },
          {
            'icon': Icons.near_me_rounded,
            'title': '२. जवळच्या दुकानांची यादी',
            'desc': 'ॲप तुमच्या सर्वात जवळ असलेली दुकाने आधी दाखवते ज्यामुळे वेळ आणि पेट्रोल वाचते.',
            'tip': '💡 टिप: जवळच्या दुकानाला आधी भेट द्या.',
          },
          {
            'icon': Icons.navigation_rounded,
            'title': '३. १-क्लिक नेव्हिगेशन',
            'desc': '"Navigate" वर क्लिक करून दुकानापर्यंतचा सर्वात सोपा मार्ग पहा.',
            'tip': '💡 टिप: ॲपमध्ये थेट नकाशा दिसतो.',
          },
          {
            'icon': Icons.check_circle_rounded,
            'title': '४. दुकानात चेक-इन व फोटो सबमिट करा',
            'desc': 'दुकानच्या १०० मीटर जवळ पोहोचताच चेक-इन सुरू होते. फोटो काढून सबमिट करा.',
            'tip': '💡 टिप: डिजिटल स्वाक्षरी देखील घेता येते.',
          },
          {
            'icon': Icons.wifi_off_rounded,
            'title': '५. ऑफलाइन मोड आणि ऑटो सिंक',
            'desc': 'इंटरनेट नसतानाही ॲप काम करते आणि नेट आल्यावर डेटा आपोआप सेव्ह होतो.',
            'tip': '💡 टिप: डेटा सुरक्षित राहतो.',
          },
        ];

      case UserGuideLanguage.bengali:
        return [
          {
            'icon': Icons.camera_alt_rounded,
            'title': '১. সেলফি ও জিপিএস হাজিরা (Punch-In)',
            'desc': 'সকালে অ্যাপ খুলে সেলফি তুলে "Punch In" বাটনে ক্লিক করুন। আপনার ডিউটি শুরু হবে।',
            'tip': '💡 টিপস: জিপিএস লোকেশন সবসময় অন রাখুন।',
          },
          {
            'icon': Icons.near_me_rounded,
            'title': '২. নিকটবর্তী দোকানের তালিকা',
            'desc': 'অ্যাপ আপনার সবচেয়ে কাছের দোকানগুলো প্রথমে দেখায় যাতে সময় ও খরচ বাঁচে।',
            'tip': '💡 টিপস: দূরত্ব অনুযায়ী সাজানো তালিকা দেখুন।',
          },
          {
            'icon': Icons.navigation_rounded,
            'title': '৩. সরাসরি ম্যাপে রুট নেভিগেশন',
            'desc': '"Navigate" চাপলে দোকানে যাওয়ার সবচেয়ে সহজ পথ দেখাবে।',
            'tip': '💡 টিপস: অ্যাপের মধ্যেই ম্যাপ সাপোর্ট করে।',
          },
          {
            'icon': Icons.check_circle_rounded,
            'title': '৪. দোকানে চেক-ইন ও ফটো প্রুফ জমা',
            'desc': 'দোকানের ১০০ মিটারের মধ্যে পৌঁছালে চেক-ইন করুন এবং ছবি তুলে সাবমিট করুন।',
            'tip': '💡 টিপস: কাস্টমার সাইনও যুক্ত করা যায়।',
          },
          {
            'icon': Icons.wifi_off_rounded,
            'title': '৫. অফলাইন মোড ও অটো-সিঙ্ক',
            'desc': 'ইন্টারনেট না থাকলেও কাজ চলবে এবং নেট পেলেই স্বয়ংক্রিয়ভাবে আপলোড হবে।',
            'tip': '💡 টিপস: ডেটা হারানোর কোনো ভয় নেই।',
          },
        ];

      case UserGuideLanguage.tamil:
        return [
          {
            'icon': Icons.camera_alt_rounded,
            'title': '1. செல்ஃபி மற்றும் GPS வருகைப்பதிவு (Punch-In)',
            'desc': 'காலையில் ஆப் திறந்து செல்ஃபி எடுத்து "Punch In" அழுத்தவும். வேலை நேரம் தொடங்கும்.',
            'tip': '💡 குறிப்பு: இருப்பிட அனுமதியை எப்போதும் இயக்கத்தில் வைக்கவும்.',
          },
          {
            'icon': Icons.near_me_rounded,
            'title': '2. அருகிலுள்ள கடைகளின் பட்டியல்',
            'desc': 'உங்களுக்கு மிக அருகில் உள்ள கடைகளை ஆப் முதலில் காட்டும்.',
            'tip': '💡 குறிப்பு: பெட்ரோல் மற்றும் நேரத்தை மிச்சப்படுத்தலாம்.',
          },
          {
            'icon': Icons.navigation_rounded,
            'title': '3. 1-கிளிக் வழித்தடம் (Navigation)',
            'desc': '"Navigate" பட்டனை அழுத்தி கடைக்கான எளிய பாதையைப் பின்பற்றவும்.',
            'tip': '💡 குறிப்பு: மிகக் குறுகிய பாதை காட்டப்படும்.',
          },
          {
            'icon': Icons.check_circle_rounded,
            'title': '4. செக்-இன் மற்றும் புகைப்பட சான்று',
            'desc': 'கடையின் 100m தூரத்திற்குள் சென்றதும் செக்-இன் செய்து புகைப்படம் பதிவேற்றவும்.',
            'tip': '💡 குறிப்பு: வாடிக்கையாளர் கையொப்பமும் பெறலாம்.',
          },
          {
            'icon': Icons.wifi_off_rounded,
            'title': '5. ஆஃப்லைன் முறை (Offline Mode)',
            'desc': 'இணையம் இல்லாத இடங்களிலும் ஆப் செயல்படும், இணையம் கிடைத்ததும் தானாக பதிவேறும்.',
            'tip': '💡 குறிப்பு: எந்த தகவலும் அழியாது.',
          },
        ];

      case UserGuideLanguage.english:
        return [
          {
            'icon': Icons.camera_alt_rounded,
            'title': '1. GPS + Selfie Attendance (Punch-In)',
            'desc': 'Open the app in the morning. Your GPS location is verified instantly. Snap a verification selfie and tap "Punch In" to activate duty.',
            'tip': '💡 Pro Tip: Keep location permission set to "Always Allow" for accurate tracking.',
          },
          {
            'icon': Icons.near_me_rounded,
            'title': '2. Proximity-Sorted Shop Directory',
            'desc': 'The app automatically sorts assigned shops with the nearest locations first, saving travel time and fuel costs.',
            'tip': '💡 Pro Tip: Tap on any shop to reveal contact person details and call shortcuts.',
          },
          {
            'icon': Icons.navigation_rounded,
            'title': '3. 1-Tap In-App Navigation',
            'desc': 'Tap the "Navigate" button on any shop card to display turn-by-turn routing directly inside the map view.',
            'tip': '💡 Pro Tip: Enjoy seamless integrated Google Maps & OSRM routing.',
          },
          {
            'icon': Icons.check_circle_rounded,
            'title': '4. Radial Check-In & Proof Photo Submission',
            'desc': 'As soon as you arrive within the shop\'s 100-meter geofence, the Check-in button illuminates green. Take a storefront photo, log notes, and submit.',
            'tip': '💡 Pro Tip: Collect digital customer signatures directly on the mobile screen.',
          },
          {
            'icon': Icons.wifi_off_rounded,
            'title': '5. Offline Resilience & Automatic Sync',
            'desc': 'Working in a basement or remote zone with no connectivity? All visit records and photos save locally to SQLite and sync automatically when internet restores.',
            'tip': '💡 Pro Tip: Never worry about lost records or dropped network connections.',
          },
        ];

      case UserGuideLanguage.hinglish:
      default:
        return [
          {
            'icon': Icons.camera_alt_rounded,
            'title': '1. GPS + Selfie Attendance (Punch-In)',
            'desc': 'Subah app open karein. Aapki GPS location verify hogi. Ek live selfie click karein aur "Punch In" dabayein. Duty start ho jayegi.',
            'tip': '💡 Pro Tip: Location permission "Always Allow" par set rakhein.',
          },
          {
            'icon': Icons.near_me_rounded,
            'title': '2. Sabse Paas Wali Shops (Nearest First)',
            'desc': 'App automatically aapke sabse nazdeek wali shops ko top par dikhata hai taaki petrol aur time dono bachein.',
            'tip': '💡 Pro Tip: Shop card par tap karke contact number aur client name dekhein.',
          },
          {
            'icon': Icons.navigation_rounded,
            'title': '3. 1-Tap Map Navigation',
            'desc': 'Shop card par "Navigate" button dabayein. Map par shop tak ka shortest rasta turant dikh jayega.',
            'tip': '💡 Pro Tip: In-app turn-by-turn route line follow karein.',
          },
          {
            'icon': Icons.check_circle_rounded,
            'title': '4. Geofenced Check-In & Photo Proof',
            'desc': 'Jaise hi aap shop ke 100 meter ke radius me pahuchenge, Check-in button green ho jayega. Live store photo click karein aur submit karein.',
            'tip': '💡 Pro Tip: Client ka digital signature bhi screen par le sakte hain.',
          },
          {
            'icon': Icons.wifi_off_rounded,
            'title': '5. Offline Mode & Auto Sync',
            'desc': 'Agar basement ya gaon me internet nahi hai, tab bhi app smoothly work karega. Internet aate hi data automatic server par sync ho jayega.',
            'tip': '💡 Pro Tip: Data loss hone ka koi tension nahi hai.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _isAdminView ? _getAdminSteps() : _getEmployeeSteps();

    final filteredSteps = _searchQuery.isEmpty
        ? steps
        : steps.where((s) {
            final t = s['title'].toString().toLowerCase();
            final d = s['desc'].toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return t.contains(q) || d.contains(q);
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAdminView ? 'Admin Command User Guide' : 'Field Employee User Guide',
                        style: AppTypography.headingMedium(isDark: isDark).copyWith(fontSize: 16),
                      ),
                      Text(
                        'Step-by-step interactive manual & feature walkthrough',
                        style: AppTypography.bodySmall(isDark: isDark).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Role Switcher & Language Selector Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Role Toggle (Admin vs Employee)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isAdminView = true),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isAdminView ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🏢 Admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isAdminView ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _isAdminView = false),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isAdminView ? AppColors.liveGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '📱 Employee',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !_isAdminView ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Multi-Language Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserGuideLanguage>(
                      value: _selectedLang,
                      icon: const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
                      isDense: true,
                      items: UserGuideLanguage.values.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Text(
                            _getLanguageLabel(lang),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLang = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search guide topics (e.g. Geofence, Punch-in, Route)...',
                        hintStyle: TextStyle(fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Step Cards List
          Expanded(
            child: filteredSteps.isEmpty
                ? Center(
                    child: Text(
                      'No guide topics match "$_searchQuery"',
                      style: AppTypography.bodyMedium(isDark: isDark),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSteps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, idx) {
                      final item = filteredSteps[idx];
                      return DepthCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['desc'] as String,
                              style: AppTypography.bodyMedium(isDark: isDark).copyWith(fontSize: 12.5, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.liveGreen.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                item['tip'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
