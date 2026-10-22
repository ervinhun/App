<!--
Flutter PR template. Drawn from contracts/definition-of-done.md §1 (Task/PR)
and §2 (User story), mobile-relevant items only — no coverage-threshold or
CSharpier checks here, those are backend-specific and live in that repo's
template instead.
-->

## What & why

<!-- One or two sentences: what this PR does and why. -->

**Story / task ID:** <!-- e.g. US-30, task 30.4 -->

## Definition of Done

- [ ] CI is green: `dart format`, `flutter analyze --fatal-infos`, `flutter test` (`ci.yml`)
- [ ] New or changed logic has an accompanying widget/unit test — not just "it looked right when I tapped through it"
- [ ] Verified on a real Android device **and** the iOS simulator; a real iPhone if this touches camera, push notifications, or background execution (those don't work correctly in the simulator)
- [ ] User-facing strings go through the l10n ARB files, no hard-coded text (mandatory from Sprint 3 onward, see `scrum.md`)
- [ ] Error, empty, and loading states handled for every screen this PR touches
- [ ] No leftover debug `print()`/`debugPrint()` calls, no commented-out code, no TODO without a linked task
- [ ] At least one teammate requested as reviewer
- [ ] Short note added to the contribution log

## Testing notes

<!-- Which devices/simulators did you actually test on? Anything a reviewer should specifically try? -->

## Screenshots / screen recording

<!-- For anything UI-visible, a before/after or a short clip saves the reviewer a build. -->

## Anything the reviewer should know

<!-- Known limitations, follow-up work intentionally left out of this PR, risky areas to look at closely. -->
