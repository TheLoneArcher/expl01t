# CampX
### Next-Generation Campus Intelligence System

CampX is a high-performance campus management application built with Flutter and Firebase. It provides a centralized, OS-inspired experience for students and instructors, featuring real-time data synchronization, artificial intelligence integration, and advanced data visualization.

---

## Key Features

### Core Modules
- **Dynamic Landing Page:** A sophisticated entry point with support for dark and light modes, including smooth visual transitions.
- **Role-Based Dashboards:** Customized experiences tailored specifically for students and instructors.
- **Academic Progress Tracking:** Interactive visualization of subject-wise performance using advanced charting libraries.
- **Task Management:** Real-time tracking of homework and assignments with Firestore integration.
- **Integrated Calendar:** Centralized management for schedules, timetables, and campus events.
- **Announcements System:** Real-time communication channel from instructors to the student body.

### Artificial Intelligence
- **CampX AI Platform:** Integrated campus assistant powered by the Gemini 1.5 Flash model via the Google Generative AI SDK.
- **Contextual Assistance:** Provides support for academic inquiries, project guidance, and general campus information.

---

## Technical Stack

- **Frontend:** Flutter SDK
- **Backend Infrastructure:** Google Firebase (Firestore)
- **AI Engine:** Google Generative AI (Gemini 1.5 Flash)
- **Typography:** Google Fonts (Orbitron, Exo 2, Share Tech Mono)
- **Data Visualization:** FL Chart

---

## Getting Started

### Prerequisites
- Flutter SDK established on the development machine.
- Google Gemini API Key (accessible via Google AI Studio).
- Configured Firebase project.

### Installation and Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/camp-x.git
   cd camp_x
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   Create a `.env` file in the root directory and add your Google Gemini API key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

4. **Execution**
   ```bash
   flutter run
   ```

---

## Design System
CampX implements a custom design language characterized by:
- **High-Contrast Aesthetics:** Modern color palettes with precise highlighting.
- **Interface Clarity:** Utilization of glassmorphism and depth-based layouts.
- **Geometric Frameworks:** Structured background patterns and consistent spacing.
- **Refined Transitions:** Smooth micro-animations for an enhanced user experience.

---

## License
This project is licensed under the MIT License. Refer to the LICENSE file for further details.

---
Development focused on modernizing educational management systems.
