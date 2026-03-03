import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Bug Condition Exploration Test for Android Desugaring Fix
///
/// **Validates: Requirements 1.1, 2.1**
///
/// This test verifies the bug condition exists on UNFIXED code:
/// - The android/app/build.gradle.kts is missing coreLibraryDesugaringEnabled flag
/// - The desugar_jdk_libs dependency is missing
/// - Android build fails with "requires core library desugaring" error
///
/// **EXPECTED OUTCOME ON UNFIXED CODE**: This test MUST FAIL
/// - Failure confirms the bug exists
/// - Counterexamples demonstrate the build error
///
/// **EXPECTED OUTCOME AFTER FIX**: This test MUST PASS
/// - Success confirms the bug is fixed
/// - Android builds complete successfully
///
/// This is a scoped property-based test that checks the concrete failing case:
/// Android build with flutter_local_notifications dependency requiring desugaring.
void main() {
  group('Bug Condition Exploration - Android Desugaring Error', () {
    test('Property 1: Fault Condition - Android Build Failure Without Desugaring', () async {
      // **Property**: For the Android build context where dependencies require
      // core library desugaring (flutter_local_notifications v17.0.0), the build
      // SHALL complete successfully with desugaring enabled.
      //
      // **On UNFIXED code**: This property is VIOLATED (test fails)
      // **After fix**: This property is SATISFIED (test passes)

      print('\n=== Running Bug Condition Exploration Test ===');
      print('Testing Android build with flutter_local_notifications dependency');
      print('EXPECTED ON UNFIXED CODE: Test FAILS (proves bug exists)');
      print('EXPECTED AFTER FIX: Test PASSES (proves bug is fixed)\n');

      // Test Case 1: Check build.gradle.kts for desugaring configuration
      print('Test Case 1: Checking android/app/build.gradle.kts for desugaring config...');
      final gradleFile = File('android/app/build.gradle.kts');
      
      if (!await gradleFile.exists()) {
        print('❌ COUNTEREXAMPLE FOUND: android/app/build.gradle.kts does not exist');
        print('Cannot verify desugaring configuration');
        fail('Gradle configuration file not found');
      }
      
      final gradleContent = await gradleFile.readAsString();
      
      // Check if coreLibraryDesugaringEnabled is set
      final hasDesugaringEnabled = gradleContent.contains('coreLibraryDesugaringEnabled');
      
      // Check if desugar_jdk_libs dependency is present
      final hasDesugarLibrary = gradleContent.contains('desugar_jdk_libs');
      
      if (!hasDesugaringEnabled) {
        print('❌ COUNTEREXAMPLE FOUND: coreLibraryDesugaringEnabled is NOT set in compileOptions');
        print('Current compileOptions only has sourceCompatibility and targetCompatibility');
        print('Missing: coreLibraryDesugaringEnabled = true');
        print('\nThis confirms part of the root cause: missing desugaring flag.');
      } else {
        print('✓ coreLibraryDesugaringEnabled is set in compileOptions');
      }

      if (!hasDesugarLibrary) {
        print('❌ COUNTEREXAMPLE FOUND: desugar_jdk_libs dependency is NOT declared');
        print('Missing: coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")');
        print('\nThis confirms part of the root cause: missing desugaring library dependency.');
      } else {
        print('✓ desugar_jdk_libs dependency is declared');
      }

      // Test Case 2: Check pubspec.yaml for flutter_local_notifications
      print('\nTest Case 2: Checking pubspec.yaml for flutter_local_notifications...');
      final pubspecFile = File('pubspec.yaml');
      final pubspecContent = await pubspecFile.readAsString();
      
      final hasNotificationsDep = pubspecContent.contains('flutter_local_notifications:');
      
      if (hasNotificationsDep) {
        print('✓ flutter_local_notifications is declared in pubspec.yaml');
        print('This dependency requires core library desugaring');
      } else {
        print('⚠️  flutter_local_notifications is NOT in pubspec.yaml');
        print('Note: The bug may not manifest without this dependency');
      }

      // Test Case 3: Attempt Android build (this is the critical test)
      print('\nTest Case 3: Attempting Android build with flutter build apk...');
      print('This will take some time and is expected to fail on unfixed code...\n');
      
      // Run flutter build apk with a timeout
      final buildResult = await Process.run(
        'flutter',
        ['build', 'apk', '--debug'],
        runInShell: true,
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print('⚠️  Build command timed out after 5 minutes');
          return ProcessResult(0, 124, '', 'Timeout');
        },
      );

      print('Flutter build exit code: ${buildResult.exitCode}');
      
      final buildFailed = buildResult.exitCode != 0 && buildResult.exitCode != 124;
      final buildTimedOut = buildResult.exitCode == 124;
      
      if (buildFailed) {
        final output = buildResult.stdout.toString() + buildResult.stderr.toString();
        
        // Check for the specific desugaring error
        final hasDesugaringError = output.contains('requires core library desugaring');
        final mentionsNotifications = output.contains('flutter_local_notifications');
        final mentionsMetadataTask = output.contains('checkDebugAarMetadata') || 
                                     output.contains('checkAarMetadata');
        
        print('Build output analysis:');
        print('- Contains "requires core library desugaring": $hasDesugaringError');
        print('- Mentions flutter_local_notifications: $mentionsNotifications');
        print('- Mentions checkDebugAarMetadata task: $mentionsMetadataTask');
        
        if (hasDesugaringError) {
          print('\n❌ COUNTEREXAMPLE FOUND: Build failed with desugaring error');
          print('Error: Dependency requires core library desugaring to be enabled');
          
          // Extract relevant error lines
          final lines = output.split('\n');
          final errorLines = lines.where((line) => 
            line.contains('desugaring') || 
            line.contains('flutter_local_notifications') ||
            line.contains('checkDebugAarMetadata')
          ).take(5);
          
          if (errorLines.isNotEmpty) {
            print('\nRelevant error output:');
            for (final line in errorLines) {
              print('  $line');
            }
          }
        } else {
          print('\n⚠️  Build failed but not with expected desugaring error');
          print('First 500 chars of output:');
          print(output.substring(0, output.length > 500 ? 500 : output.length));
        }
      } else if (buildResult.exitCode == 0) {
        print('✓ Build completed successfully (no errors)');
      } else if (buildTimedOut) {
        print('⚠️  Build timed out, cannot verify build failure');
      }

      // **ASSERTION**: The property is satisfied when:
      // 1. coreLibraryDesugaringEnabled is set in build.gradle.kts
      // 2. desugar_jdk_libs dependency is declared
      // 3. Android build completes successfully (exit code 0)
      //
      // **ON UNFIXED CODE**: These conditions are NOT met, so test FAILS
      // **AFTER FIX**: These conditions ARE met, so test PASSES

      print('\n=== Test Assertion ===');
      print('Property: Android build completes successfully with desugaring enabled');
      print('Condition 1 - coreLibraryDesugaringEnabled set: $hasDesugaringEnabled');
      print('Condition 2 - desugar_jdk_libs dependency declared: $hasDesugarLibrary');
      print('Condition 3 - Build succeeded: ${buildResult.exitCode == 0}');

      final propertyIsSatisfied = hasDesugaringEnabled && 
                                  hasDesugarLibrary && 
                                  buildResult.exitCode == 0;

      if (!propertyIsSatisfied) {
        print('\n❌ PROPERTY VIOLATED: Bug condition exists');
        print('Expected behavior: Android build should succeed with desugaring enabled');
        print('Actual behavior: Build fails due to missing desugaring configuration');
        print('\nCounterexamples documented:');
        if (!hasDesugaringEnabled) {
          print('1. Missing coreLibraryDesugaringEnabled flag in compileOptions');
        }
        if (!hasDesugarLibrary) {
          print('2. Missing desugar_jdk_libs dependency in dependencies block');
        }
        if (buildFailed) {
          print('3. Build failed at checkDebugAarMetadata task with exit code ${buildResult.exitCode}');
        }
        if (buildTimedOut) {
          print('3. Build timed out (could not complete verification)');
        }
      } else {
        print('\n✓ PROPERTY SATISFIED: Bug is fixed');
        print('Android build completes successfully with desugaring properly configured');
      }

      // The assertion: property must be satisfied (true)
      // On UNFIXED code: this will FAIL (expected)
      // After fix: this will PASS (expected)
      expect(
        propertyIsSatisfied,
        isTrue,
        reason: 'Property violated: Android build should complete successfully with '
                'core library desugaring enabled for flutter_local_notifications dependency. '
                'Counterexamples: ${!hasDesugaringEnabled ? "missing coreLibraryDesugaringEnabled flag, " : ""}'
                '${!hasDesugarLibrary ? "missing desugar_jdk_libs dependency, " : ""}'
                '${buildFailed ? "build failed with exit code ${buildResult.exitCode}" : ""}',
      );
    }, timeout: const Timeout(Duration(minutes: 6)));
  });
}
