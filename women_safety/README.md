# Women Safety App (Flutter)

> Empowering personal safety with real-time guardians, AI risk prediction, distress detection, and rapid SOS escalation.

## ✨ Core Features
| Category | Features |
|----------|----------|
| Emergency | 9-step SOS orchestration, smart call escalation, alarm, evidence capture (photo/audio/video) |
| Communication | SMS, WhatsApp, Email, Push Notifications |
| Guardians | Live tracking, management, network volunteers, route deviation alerts |
| AI / ML | Voice distress analysis, face recognition, danger zone prediction (TFLite) |
| Journey Safety | Ride tracking (Uber/Ola), safe journey monitoring, shake-to-SOS, voice activation |
| Advanced | Live video streaming (Agora), Panic home widget, AI recommendations |

## 🚀 Quick Start
```powershell
git clone <repo-url>
cd women_safety
flutter pub get
flutter run
```

## 🔧 Configuration Checklist
| Integration | Action |
|-------------|--------|
| Firebase | Add `android/app/google-services.json` & iOS `GoogleService-Info.plist` |
| Agora | Replace placeholder `YOUR_AGORA_APP_ID` in `live_streaming_service.dart` |
| TFLite Model | Add `assets/models/danger_prediction_model.tflite` (or use rule-based fallback) |
| Android Widget | Implement `PanicWidgetProvider` + layouts (see `CONFIGURATION_SETUP.md`) |
| Permissions | Ensure microphone, camera, location, vibration, notifications granted |

## 🛡️ Security & Privacy
No secrets in source control. Users must supply their own Firebase, Agora credentials. Avoid uploading real personal guardian data.

## 🧠 Architecture
- **State**: Bloc / Cubits for theming & auth
- **Services**: Modular safety services under `lib/services/`
- **Screens**: Feature-driven UI (`revolutionary_features_screen.dart` hub)
- **Data**: Firestore collections (`rides`, `guardian_faces`, `danger_zones`, etc.)
- **Extensibility**: Drop-in AI models, replace notification layer, add map provider

## 📱 UI / Theming Roadmap
- Central design tokens (`AppTheme`) for color, typography, elevation
- Animated transitions for SOS activation & risk escalation
- Feature status chips (Safe / Monitoring / Alerting)
- Accessibility: contrast validation & semantic labels

## 🧪 Testing
```powershell
flutter test          # Unit & widget tests
flutter run           # Manual feature testing
```
See `QUICK_TEST_GUIDE.md` for scenario-based validation.

## 🗺️ Roadmap
- [ ] Multi-language interface (EN + regional)
- [ ] Encrypted local evidence queue
- [ ] Guardian Web Dashboard
- [ ] ML model personalization (user voice baseline)
- [ ] Battery usage optimization profile
- [ ] Offline map tile caching
- [ ] Secure plugin for law-enforcement escalation

## 🤝 Contributing
Read `CONTRIBUTING.md` and open a feature request. Use conventional commits.

## 📄 License
Released under the MIT License (see `LICENSE`).

## 🆘 Community & Support
- GitHub Issues (bugs & enhancements)
- Security concerns: see `SECURITY.md`

## 📚 Flutter Resources
- [Write your first app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook Samples](https://docs.flutter.dev/cookbook)

---
*Building technology that helps protect and empower.*
