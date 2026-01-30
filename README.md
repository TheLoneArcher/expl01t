# CampX 🚀
### Next-Generation Campus Intelligence System

CampX is a high-performance, techno-aesthetic campus management application built with Flutter and Firebase. It provides a centralized "OS-like" experience for students and instructors, featuring real-time data, AI integration, and advanced data visualization.

---

## ✨ Key Features

### 🏢 Core Modules
- **Dynamic Landing Page**: A stunning, animated entry point with techno-dark/light mode support and smooth visualizers.
- **Role-Based Dashboards**: Tailored experiences for both **Students** and **Instructors**.
- **Academic Growth Tracking**: Interactive subject-wise progress visualization using `fl_chart`.
- **Homework & Tasks**: Persistent task tracking with real-time Firestore updates.
- **Smart Calendar**: Integrated timetable and event management.
- **Real-Time Announcements**: Instant updates for students from the instructor panel.

### 🤖 AI Intelligence
- **CampX AI (Gemini 1.5 Flash)**: A built-in campus assistant integrated using the `google_generative_ai` SDK.
- **Context-Aware Assistance**: Helps with academic queries, project guidance, and campus life questions.

---

## 🛠 Tech Stack

- **Frontend**: Flutter (3.x)
- **Backend/DB**: Google Firebase (Firestore)
- **AI Engine**: Google Generative AI (Gemini 1.5 Flash)
- **Typography**: Google Fonts (Orbitron, Exo 2, Share Tech Mono)
- **Charts**: FL Chart

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- A Google Gemini API Key (get it from [Google AI Studio](https://aistudio.google.com/))
- Firebase project configured

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/camp-x.git
   cd camp_x
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Key**
   Open `lib/screens/tabs/chat_tab.dart` and add your API key:
   ```dart
   static const String _apiKey = "YOUR_API_KEY_HERE";
   ```

4. **Run the application**
   ```bash
   flutter run -d edge
   ```

---

## 🎨 Aesthetic Design System
CampX uses a custom **"Techno-Dark"** theme characterized by:
- **Neon Accents**: Cyberpunk-inspired cyan, pink, and green highlights.
- **Glassmorphism**: Translucent cards and blurred backgrounds.
- **Grid Patterns**: Subtle geometric background textures.
- **Micro-animations**: Smooth transitions and animated visualizers.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Built with ❤️ for Modern Education.
