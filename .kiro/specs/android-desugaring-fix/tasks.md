# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Fault Condition** - Android Build Failure Without Desugaring
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For this deterministic build configuration bug, scope the property to concrete failing build commands
  - Test that Android build commands fail with desugaring error on UNFIXED configuration
  - Test implementation details from Fault Condition in design:
    - Verify `flutter build apk` fails with exit code 1
    - Verify error message contains "requires core library desugaring"
    - Verify error mentions `:flutter_local_notifications` dependency
    - Verify failure occurs at `:app:checkDebugAarMetadata` task
  - The test assertions should match the Expected Behavior Properties from design (build success after fix)
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 2.1_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Android Platform Builds
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-Android builds (iOS, web, Dart analysis)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements:
    - iOS builds complete successfully (if on macOS)
    - Web builds complete successfully
    - Dart analysis completes successfully
    - Hot reload functionality works correctly
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 3. Fix for Android core library desugaring configuration

  - [ ] 3.1 Enable core library desugaring in android/app/build.gradle.kts
    - Add `coreLibraryDesugaringEnabled = true` to the `compileOptions` block
    - Add `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")` to the `dependencies` block
    - Verify `sourceCompatibility` and `targetCompatibility` remain at `JavaVersion.VERSION_17`
    - Verify `kotlinOptions.jvmTarget` remains at Java 17
    - _Bug_Condition: isBugCondition(buildContext) where buildContext.platform == 'android' AND buildContext.hasDependencyRequiringDesugaring('flutter_local_notifications') AND NOT buildContext.compileOptions.coreLibraryDesugaringEnabled_
    - _Expected_Behavior: Android builds complete successfully with exit code 0, no desugaring errors_
    - _Preservation: iOS/web builds, Dart analysis, hot reload, and existing Android functionality remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4_

  - [ ] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Android Build Success with Desugaring
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify Android build commands succeed:
      - `flutter build apk` completes with exit code 0
      - No error messages about desugaring
      - APK is generated in `build/app/outputs/flutter-apk/`
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-Android Platform Builds
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions):
      - iOS builds still work (if on macOS)
      - Web builds still work
      - Dart analysis still works
      - Hot reload still works
      - Existing Android app functionality still works

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
