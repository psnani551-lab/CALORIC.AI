# Caloric.AI 🥗🤖

**Caloric.AI** is a professional, high-performance health transformation application that combines cutting-edge AI intelligence with reactive backend architecture to help users achieve their nutritional goals with precision.

![Caloric.AI Banner](mobile/assets/app_icon.png)

## 🚀 Key Features

### 🧠 Intelligence Engine (GPT-4o-mini)
- **AI Coach**: A deeply intelligent nutrition companion that provides personalized advice based on real-time data.
- **AI Scanner**: High-precision multimodal vision for scanning meals and instant calorie estimation.
- **Context-Aware**: The AI understands your daily progress, weight trends, and hydration levels for truly proactive coaching.

### ⚡ Reactive Performance
- **Single Source of Truth**: Powered by a reactive `DataRepository` for instant synchronization across all features.
- **Offline Reliability**: Robust local caching for seamless transitions between connectivity states.
- **Hardened Security**: Supabase-powered backend with strict Row Level Security (RLS) policies.

### 🎨 Premium Experience
- **Fluid UI**: Modern, dark-mode-first design featuring Google Fonts (Outfit).
- **Precision Controls**: High-precision biometrics inputs with tactile increment/decrement controls.
- **Interactive Dashboards**: Real-time rings for macros (Calories, Protein, Carbs, Fats) and hydration tracking.

## 🛠️ Technology Stack
- **Framework**: Flutter (Android Focus)
- **Intelligence**: OpenAI API (GPT-4o-mini & Vision)
- **Backend**: Supabase (Auth, Database, Storage)
- **State Management**: BLoC / RxDart
- **Storage**: SharedPreferences (User-isolated session state)

## 📦 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- OpenAI API Key
- Supabase Project URL & Anon Key

### Installation
1. Clone the repository: `git clone https://github.com/psnani551-lab/CALORIC.AI.git`
2. Install dependencies: `flutter pub get`
3. Configure `AppConfig`: Update `mobile/lib/core/config/app_config.dart` with your API keys.
4. Run the app: `flutter run`

## 🏗️ Architecture
The app follows a professional layered architecture:
- **Presentation Layer**: BLoC pattern for predictable state transitions.
- **Domain/Data Layer**: Centralized repository for reactive data governance.
- **Service Layer**: Decoupled IO services for AI and Supabase integrations.

---

## 📄 License
This project is for professional demonstration purposes. All rights reserved.

Created with ❤️ for health seekers. 🚀✅🏋️‍♂️
