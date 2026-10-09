import 'ai_language_detector.dart';

class OfflineAiResponse {
  final String message;
  final bool isLiveQueryBlocked;
  final String source;

  const OfflineAiResponse({
    required this.message,
    this.isLiveQueryBlocked = false,
    this.source = 'offline_local_knowledge',
  });
}

class OfflineAiService {
  final Map<String, String> _hindiFaq = {
    'attendance': 'EmpTracker me Attendance lagane ke liye: App kholein aur "Punch In" button par click karein. GPS location verify hone ke baad attendance mark ho jayegi.',
    'visit': 'Shop Visit record karne ke liye: Map ya Shop list se dukan select karein aur geofence ke andar pahunch kar "Check In" button dabayein.',
    'leave': 'Chhutti (Leave) apply karne ke liye: Menu me jakar "Attendance & Leave" tab select karein aur form submit karein.',
    'route': 'Aaj ka assigned route dekhne ke liye: "Today Route" tab kholein jaha pending aur completed shops dikhenge.',
  };

  final Map<String, String> _englishFaq = {
    'attendance': 'To mark attendance in EmpTracker: Open the dashboard and tap "Punch In". Your GPS location will be verified and attendance recorded.',
    'visit': 'To record a shop visit: Select the store from your route or shop list and tap "Check In" once within the geofence radius.',
    'leave': 'To request leave: Navigate to the "Attendance & Leave" section from the menu and submit your request.',
    'route': 'To view today\'s assigned route: Open the "Today Route" tab to see pending and completed stores.',
  };

  /// Query offline knowledge base
  OfflineAiResponse handleOfflineQuery(String query) {
    final lower = query.toLowerCase();
    final lang = AiLanguageDetector.detect(query);
    final isHindiOrHinglish = lang == 'hi' || lang == 'hinglish';

    // 1. Strict Domain Hardening / Out-of-Scope Guardrails Check
    final isOutOfScope = _checkOutOfScope(lower);
    if (isOutOfScope) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: '⚠️ क्षमा करें, मैं केवल EmpTracker / FieldForce प्लेटफॉर्म (जैसे Field Attendance, Live Tracking, Shop Visits, Routes, Orders और Field Staff) से जुड़े सवालों के लिए तैयार किया गया हूँ। कृपया प्रोजेक्ट से संबंधित प्रश्न पूछें।',
          source: 'domain_guardrail_hardened',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: '⚠️ Sorry, main sirf EmpTracker FieldForce platform (Attendance, Live GPS Tracking, Shop Visits, Daily Routes, Orders aur Field Staff) se jude sawalon ke liye train kiya gaya hoon. Kripya project se related sawal poochein.',
          source: 'domain_guardrail_hardened',
        );
      } else {
        return const OfflineAiResponse(
          message: '⚠️ I am strictly configured to assist only with EmpTracker FieldForce operations (such as Attendance, Live GPS Tracking, Shop Visits, Daily Routes, Orders, and Field Staff). Please ask a project-related query.',
          source: 'domain_guardrail_hardened',
        );
      }
    }

    // 2. Check for live telemetry intents (location, real-time speed, live radar)
    if (lower.contains('kaha') || 
        lower.contains('kahan') || 
        lower.contains('where is') || 
        lower.contains('location') || 
        lower.contains('live') || 
        lower.contains('radar')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: '⚠️ लाइव लोकेशन और रडार टेलीमेट्री देखने के लिए एक्टिव इंटरनेट कनेक्शन आवश्यक है। ऑफलाइन मोड में लाइव लोकेशन उपलब्ध नहीं है।',
          isLiveQueryBlocked: true,
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: '⚠️ Live location aur radar telemetry dekhne ke liye active internet connection zaroori hai. Offline mode me live location available nahi hai.',
          isLiveQueryBlocked: true,
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: '⚠️ Live employee location and radar telemetry requires an active internet connection. It is not available in offline mode.',
          isLiveQueryBlocked: true,
          source: 'local_engine',
        );
      }
    }

    // 3. Check for write actions (task assignment, notes)
    if (lower.contains('assign') || 
        lower.contains('note add') || 
        lower.contains('remark')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: '⚠️ टास्क असाइन करने या रिकॉर्ड अपडेट करने के लिए सर्वर कनेक्शन आवश्यक है। ऑफलाइन राइट ऑपरेशन्स की अनुमति नहीं है।',
          isLiveQueryBlocked: true,
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: '⚠️ Task assign karne ya record update karne ke liye server connection zaroori hai. Offline write actions allowed nahi hain.',
          isLiveQueryBlocked: true,
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: '⚠️ Task assignments and updates require a live server connection. Offline write actions are disabled.',
          isLiveQueryBlocked: true,
          source: 'local_engine',
        );
      }
    }

    // 4. In-Scope Domain Handlers (Shop Visits / Check in)
    if (lower.contains('visit') || lower.contains('check in') || lower.contains('geofence')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: 'दुकान विजिट दर्ज करने के लिए: मैप या शॉप लिस्ट से दुकान चुनें और 50 मीटर जियोफेंस के अंदर पहुंचकर "Check In" बटन दबाएं।',
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: 'Shop Visit record karne ke liye: Map ya Shop list se dukan select karein aur geofence ke andar pahunch kar "Check In" button dabayein.',
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: 'To record a shop visit: Select the store from your route or shop list and tap "Check In" once within the geofence radius.',
          source: 'local_engine',
        );
      }
    }

    // 5. In-Scope Domain Handlers (Attendance / Punch)
    if (lower.contains('attendance') || lower.contains('haziri') || lower.contains('hazri') || lower.contains('punch in') || lower.contains('punch out') || lower.contains('हाजिरी')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: 'EmpTracker में हाजिरी लगाने के लिए: ऐप में "Punch In" बटन दबाएं। जीपीएस लोकेशन सत्यापित होते ही आपकी हाजिरी दर्ज हो जाएगी।',
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: 'EmpTracker me Attendance lagane ke liye: App kholein aur "Punch In" button par click karein. GPS location verify hone ke baad attendance mark ho jayegi.',
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: 'To mark attendance in EmpTracker: Open the dashboard and tap "Punch In". Your GPS location will be verified and attendance recorded.',
          source: 'local_engine',
        );
      }
    }

    // 6. In-Scope Domain Handlers (Leave)
    if (lower.contains('leave') || lower.contains('chhutti') || lower.contains('छुट्टी')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: 'छुट्टी आवेदन करने के लिए: मेनू में "Attendance & Leave" सेक्शन में जाएं और फॉर्म भरकर सबमिट करें।',
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: 'Chhutti (Leave) apply karne ke liye: Menu me jakar "Attendance & Leave" tab select karein aur form submit karein.',
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: 'To request leave: Navigate to the "Attendance & Leave" section from the menu and submit your request.',
          source: 'local_engine',
        );
      }
    }

    // 7. In-Scope Domain Handlers (Route / Navigation)
    if (lower.contains('route') || lower.contains('rasta') || lower.contains('रास्ता')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: 'आज का रूट देखने के लिए: "Today Route" टैब खोलें जहाँ सभी पेंडिंग और पूर्ण दुकानें क्रमबद्ध दिखाई देंगी।',
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: 'Aaj ka assigned route dekhne ke liye: "Today Route" tab kholein jaha pending aur completed shops dikhenge.',
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: 'To view today\'s assigned route: Open the "Today Route" tab to see pending and completed stores.',
          source: 'local_engine',
        );
      }
    }

    // 8. In-Scope Domain Handlers (Employees / Staff)
    if (lower.contains('active') || lower.contains('employee') || lower.contains('karmchari') || lower.contains('staff')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: 'वर्तमान में सिस्टम में 12 फील्ड कर्मचारी पंजीकृत हैं, जिनमें से 8 सक्रिय ड्यूटी पर हैं। लाइव रडार देखने के लिए इंटरनेट कनेक्ट करें।',
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: 'Abhi system me 12 field employees registered hain jisme se 8 active duty par hain. Live radar telemetry dekhne ke liye internet connect karein.',
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: 'Currently, 12 field employees are registered with 8 active on duty. Connect to the internet for live radar telemetry.',
          source: 'local_engine',
        );
      }
    }

    // 9. In-Scope Domain Handlers (Shops / Stores)
    if (lower.contains('shop') || lower.contains('dukan') || lower.contains('store')) {
      if (lang == 'hi') {
        return const OfflineAiResponse(
          message: 'आपके क्षेत्र में कुल 45 पंजीकृत दुकानें हैं, जिनमें 14 उच्च-प्राथमिकता वाले रिटेल पॉइंट्स शामिल हैं।',
          source: 'local_engine',
        );
      } else if (lang == 'hinglish') {
        return const OfflineAiResponse(
          message: 'Aapke territory me total 45 registered shops hain, jinme se 14 high-priority retail points hain.',
          source: 'local_engine',
        );
      } else {
        return const OfflineAiResponse(
          message: 'There are 45 registered shops in your territory, including 14 high-priority retail points.',
          source: 'local_engine',
        );
      }
    }

    // 10. Help / General In-Scope Guidance
    if (lang == 'hi') {
      return const OfflineAiResponse(
        message: 'EmpTracker AI सहायक: मैं फील्ड हाजिरी, दुकान विजिट, दैनिक रूट और फील्ड स्टाफ ट्रैकिंग में आपकी मदद कर सकता हूँ। आप बोलकर या लिखकर पूछ सकते हैं।',
        source: 'local_engine',
      );
    } else if (lang == 'hinglish') {
      return const OfflineAiResponse(
        message: 'EmpTracker AI Assistant: Main Attendance, Shop Visits, Daily Routes aur Field Staff telemetry me aapki madad kar sakta hoon. Aap bolkar ya type karke pooch sakte hain.',
        source: 'local_engine',
      );
    } else {
      return const OfflineAiResponse(
        message: 'EmpTracker AI Assistant: I can assist with Field Attendance, Shop Visits, Daily Routes, and Staff Telemetry. You can speak or type your question.',
        source: 'local_engine',
      );
    }
  }

  /// Strict Domain Guardrails: Check if query is unrelated to EmpTracker / FieldForce
  bool _checkOutOfScope(String lower) {
    const outOfScopeKeywords = [
      'movie', 'film', 'cinema', 'actor', 'actress', 'hero', 'gaana', 'song', 'sing',
      'bollywood', 'hollywood', 'modi', 'rahul gandhi', 'politics', 'election', 'chunav',
      'recipe', 'khana kaise', 'maggi', 'biryani', 'chai kaise', 'cook', 'cooking',
      'joke', 'chutkula', 'shayari', 'poem', 'story', 'cricket', 'ipl', 'score', 'match',
      'football', 'messi', 'ronaldo', 'weather', 'mausam', 'python code', 'react code',
      'president of', 'capital of', 'prime minister', 'dating', 'girlfriend', 'boyfriend'
    ];

    for (final kw in outOfScopeKeywords) {
      if (lower.contains(kw)) {
        return true;
      }
    }
    return false;
  }
}
