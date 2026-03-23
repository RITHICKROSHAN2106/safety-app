# Contributing Guide

Thank you for your interest in improving the Women Safety App!

## 1. Code of Conduct
Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). Be respectful and supportive.

## 2. How Can I Contribute?
- Report bugs (use the Bug Report template)
- Suggest new safety features
- Improve UI/UX & accessibility
- Optimize performance or battery usage
- Add tests (unit, widget, integration)
- Improve documentation

## 3. Development Setup
```powershell
flutter pub get
flutter run
```
Optional integrations:
- Firebase: add your own `google-services.json` (do NOT commit personal keys)
- Agora: set `AGORA_APP_ID` via `.env` or secure config service
- TFLite model: place `danger_prediction_model.tflite` in `assets/models/`

## 4. Branching Strategy
- `main`: stable
- `develop`: active integration branch
- Feature branches: `feature/<short-description>`
- Bug fix branches: `fix/<issue-number>`

## 5. Commit Convention (Conventional Commits)
Format: `type(scope): description`
Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `ci`, `chore`
Examples:
```
feat(ride-tracking): add expected route sampling
fix(voice): restart loop on no_match error
```

## 6. Pull Request Checklist
- Feature/bug has an issue reference (e.g. Closes #42)
- Code is formatted (`dart format .`)
- No unrelated changes
- Tests added or updated where sensible
- Docs updated (README / guides)
- Screenshots/GIFs for UI changes

## 7. Testing
```powershell
flutter test
```
Add widget tests for new UI components and unit tests for services.

## 8. Security & Privacy
Never include secrets, private phone numbers, or real emergency contact data in commits.

## 9. Releases
- Tag format: `v1.2.0`
- Generate changelog from conventional commits

## 10. Questions
Open a GitHub Discussion or use the `question` label on issues.

Thank you for helping build safer technology. 💙
