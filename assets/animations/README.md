# Lottie animations

Drop Lottie `.json` files here to upgrade the hand-built Flutter animations
used on the splash, onboarding, and scanning screens.

Expected filenames (all optional — each falls back to a built-in painted
animation when the file is absent):

| File                | Used by                                  |
| ------------------- | ---------------------------------------- |
| `paw_pulse.json`    | Splash logo mark                         |
| `onboarding_1.json` | Onboarding page 1 — "Snap your pet"      |
| `onboarding_2.json` | Onboarding page 2 — "AI reads symptoms"  |
| `onboarding_3.json` | Onboarding page 3 — "Vet-ready report"   |
| `scanning.json`     | Full-screen scanning state               |

See `lib/widgets/lottie_or_fallback.dart` for the loading logic.
