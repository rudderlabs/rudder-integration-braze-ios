# Integration checks

`build-and-quality-checks.yml` runs CocoaPods lint, the existing XCTest suite, and
SPM consumer builds on pull requests and pushes to `master`. CI and CocoaPods
publication use Xcode 26.2 on `macos-15` and CocoaPods 1.16.2.

## Unit tests

The `Rudder-Braze-Example` scheme runs `Example/Tests/Tests.m` in an iOS simulator.
The tests cover ecommerce property mapping. They do not need Braze credentials,
a RudderStack source, or live campaigns. A clean checkout contains only
`SampleRudderConfig.plist`, so the sample app does not initialize either SDK.
Do not add a local `RudderConfig.plist` to the test host.

Run from the repository root:

```sh
pod _1.16.2_ install --project-directory=Example
xcodebuild test \
  -workspace Example/Rudder-Braze.xcworkspace \
  -scheme Rudder-Braze-Example \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -derivedDataPath build/Tests \
  -resultBundlePath build/Tests.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

Choose an installed simulator when running locally. Use a new result bundle path
for each run. CI checks the result bundle for passing tests and zero failures,
and uploads the bundle and logs even when the test command fails.

Use `pod install`, not `pod update`, to retain the locked external dependencies.
Do not add `--deployment`: release PRs change the local pod version through
`package.json`, so CocoaPods must be able to refresh that lockfile entry.

## SPM consumer

`SPMConsumer` depends on this repository through a local package reference. Its
Swift source imports the public module and references `RudderBrazeFactory`.
The dynamic library product verifies compilation and linking without starting
either SDK. CI builds both iOS simulator architectures and the iOS device slice.

Run from `CI/SPMConsumer`:

```sh
cp ../../Package.resolved Package.resolved
xcodebuild build \
  -scheme SPMConsumer \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ../../build/SPMConsumer \
  -disableAutomaticPackageResolution \
  CODE_SIGNING_ALLOWED=NO
```

Use `generic/platform=iOS` for the device build. CI copies the root lockfile so
the consumer uses the same dependency baseline. Update the root `Package.resolved`
and `Example/Podfile.lock` deliberately when upgrading dependencies.

These checks do not verify banner dismissal, push delivery, or live Braze behavior.
Those checks belong to the SDK upgrade and release validation work.
