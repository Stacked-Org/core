## 0.1.0-beta.1 (2026-11-11)

* First release. `stackedJourney` drives a Stacked app by ViewModel and action names under `flutter test`, with no device: `precondition`, `act` (with an optional `until`), `waitFor`, `expectState`, `expectOverlay` and `currentNode`.
* `JourneyConfig` boots the app the way `main()` does. Each journey starts clean: the locator, introspection, lent actions, ViewModel registry and router are reset.
* `FixtureSet` swaps services for fakes. Real network calls are blocked and fail the journey.
