# IDentity Liveness SDK for iOS

[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-lightgrey.svg)](https://developer.apple.com)
[![Swift Tools](https://img.shields.io/badge/swift--tools-5.9-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)

The **IDentity Liveness SDK** is IDmission's face-only SDK for iOS. It performs face detection, passive
liveness detection, and face mask detection **on the device**, and supports biometric enrollment,
verification, and identification against the IDmission platform.

It does **not** capture or process identity documents. If you need document verification, use the
[Medium](https://github.com/Idmission-LLC/identityMediumSDK-SPM) or
[Lite](https://github.com/Idmission-LLC/identityLiteSDK-SPM) SDK instead.

This repository distributes the SDK as a **Swift Package** of pre-built, code-signed `.xcframework` binaries.

> [!IMPORTANT]
> This is commercial, proprietary software. Cloning or resolving this package does **not** grant you a licence
> to use it, and the SDK will not function without credentials issued by IDmission. See [LICENSE](LICENSE) and
> contact <sales@idmission.com> to obtain a commercial agreement.

---

## Table of contents

- [Which SDK flavour do I need?](#which-sdk-flavour-do-i-need)
- [Requirements](#requirements)
- [Package products](#package-products)
- [Installation](#installation)
- [Project configuration](#project-configuration)
- [Credentials and access tokens](#credentials-and-access-tokens)
- [Initializing the SDK](#initializing-the-sdk)
- [Tracking initialization progress](#tracking-initialization-progress)
- [Features](#features)
- [Localization](#localization)
- [Security controls](#security-controls)
- [Diagnostics](#diagnostics)
- [Framework sizes](#framework-sizes)
- [Versioning and releases](#versioning-and-releases)
- [Troubleshooting](#troubleshooting)
- [Support](#support)
- [Licence](#licence)

---

## Which SDK flavour do I need?

IDmission ships several iOS SDK flavours. They share one API surface; they differ in how much processing runs
on the device versus on the IDmission platform, and therefore in binary size and capability.

| Capability | **Liveness** (this SDK) | [Lite](https://github.com/Idmission-LLC/identityLiteSDK-SPM) | [Medium](https://github.com/Idmission-LLC/identityMediumSDK-SPM) |
|:---|:---:|:---:|:---:|
| Face detection | On device | On device | On device |
| Passive liveness detection | On device | On device | On device |
| Face mask detection | On device | On device | On device |
| Hat and sunglasses detection | On server | On server | On device |
| Biometric enroll, verify, identify | Yes | Yes | Yes |
| Document capture and validation | — | Yes | Yes |
| MRZ and barcode reading | — | On server | On device |
| Signature, voice, fingerprint capture | — | Optional add-ons | Optional add-ons |
| ePassport NFC chip reading | — | — | Optional add-on |

Liveness is the smallest of the three packages and the right choice for face-only use cases: login, step-up
authentication, and re-verification of an already-enrolled customer.

---

## Requirements

| | |
|:---|:---|
| **Minimum deployment target** | iOS 15.0 |
| **Xcode** | 15.0 or later |
| **Swift tools version** | 5.9 |
| **Device architecture** | `arm64` |
| **Simulator architecture** | `x86_64` only — see [Apple Silicon note](#apple-silicon-simulators) |
| **Third-party dependencies** | **None.** |
| **Network** | HTTPS access to your IDmission API host and to the model CDN |


### Apple Silicon simulators

The shipped `.xcframework` bundles contain an `arm64` device slice and an **`x86_64` simulator slice**. There
is no `arm64` simulator slice, so on an Apple Silicon Mac a default simulator build will fail to find the
module. Choose one of:

1. **Build and test on a physical device** — recommended, and required anyway for camera work.
2. **Build the simulator target as `x86_64`.** In your app target's build settings add:

   ```
   EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64
   ```

   The simulator then runs your app under Rosetta 2.

---

## Package products

| Product | Modules you `import` | Required | Purpose |
|:---|:---|:---:|:---|
| `IDentityLivenessSDK` | `IDentityLivenessSDK`, `SelfieCaptureLiveness` | **Yes** | Core SDK and selfie/liveness capture |
| `IDentityLivenessModels` | *(none — see below)* | No | Bundles the ML models **inside your app** instead of downloading them on first run |

### About `IDentityLivenessModels`

The SDK needs a set of TensorFlow Lite models for on-device face detection and liveness. You choose how they
arrive:

- **Omit the product** (default): models are downloaded from IDmission on first initialization. Smallest app
  binary, but the first launch needs network access and takes longer.
- **Include the product**: the models ship inside your app (about 12 MB uncompressed). First launch is fast
  and works without model downloads.

Either way, call `initializeSDK` with `isUpdateModelsData: true` so the SDK can refresh models when IDmission
publishes newer versions.

---

## Installation

### Xcode

1. **File → Add Package Dependencies…**
2. Enter the package URL:

   ```
   https://github.com/Idmission-LLC/identityLivenessSDK-SPM
   ```

3. Set **Dependency Rule** to **Up to Next Major Version** starting at `11.1.13`.
4. Click **Add Package**, then tick the products you need. `IDentityLivenessSDK` is mandatory.

### Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [.iOS(.v15)],
    dependencies: [
        .package(
            url: "https://github.com/Idmission-LLC/identityLivenessSDK-SPM",
            from: "11.1.13"
        )
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "IDentityLivenessSDK", package: "identityLivenessSDK-SPM"),
                // Optional:
                // .product(name: "IDentityLivenessModels", package: "identityLivenessSDK-SPM"),
            ]
        )
    ]
)
```

### Repository access

If your organisation resolves this package over SSH, or if IDmission has provisioned it as a private
repository for you, make sure Xcode has a GitHub account configured with access
(**Xcode → Settings → Accounts**), or use the SSH form of the URL:

```
git@github.com:Idmission-LLC/identityLivenessSDK-SPM.git
```

For CI, provide a deploy key or a personal access token with `repo` read scope.

---

## Project configuration

### Info.plist permissions

| Key | Required when |
|:---|:---|
| `NSCameraUsageDescription` | **Always** — every capture flow uses the front camera |
| `NSLocationWhenInUseUsageDescription` | You initialize with `isGPSEnabled: true` |

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take a selfie and confirm you are physically present.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Your location is recorded with your verification to help prevent fraud.</string>
```

### App privacy manifest

The SDK ships its **own** `PrivacyInfo.xcprivacy` inside each framework, so you do not need to redeclare the
SDK's API usage. You still need an app-level `PrivacyInfo.xcprivacy` describing **your** app. If your app code
touches the same required-reason APIs, declare them with these reason codes:

| API category | Reason codes |
|:---|:---|
| File timestamp | `C617.1`, `3B52.1` |
| System boot time | `35F9.1` |
| Disk space | `E174.1` |
| User defaults | `CA92.1`, `1C8F.1`, `C56D.1` |

Remember to complete your App Store Connect privacy nutrition labels. The SDK collects name, email, phone,
physical address, payment info, precise and coarse location, sensitive info, photos or videos, audio data,
and user ID — all linked to the user, all for app functionality, none used for tracking.

---

## Credentials and access tokens

The SDK authenticates to the IDmission platform with a short-lived OAuth access token.

> [!WARNING]
> **Mint tokens on your backend, never in the app.** Your `client_id`, `client_secret`, username, and password
> must never be embedded in the app binary or in client-side configuration. Your app should request a token
> from your own server and pass it to `initializeSDK`.

IDmission provides your credentials when you sign up. Your server exchanges them for a token:

```bash
curl --location --request POST 'https://auth.idmission.com/auth/realms/identity/protocol/openid-connect/token' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode 'client_id=YOUR_CLIENT_ID' \
  --data-urlencode 'client_secret=YOUR_CLIENT_SECRET' \
  --data-urlencode 'username=YOUR_INTEG_USER' \
  --data-urlencode 'password=YOUR_PASSWORD' \
  --data-urlencode 'scope=api_access'
```

```json
{
  "access_token": "eyJhbGciO...",
  "expires_in": 18000,
  "token_type": "Bearer",
  "scope": "email profile api_access"
}
```

Tokens expire (`expires_in` is in seconds). Re-initialize the SDK with a fresh token when it lapses.

---

## Initializing the SDK

Initialize once, early in the session, before presenting any capture flow.

```swift
import IDentityLivenessSDK
import SelfieCaptureLiveness

// Point the SDK at your IDmission environment before initializing.
IDentitySDK.apiBaseUrl = "https://api.idmission.com/"

IDentitySDK.initializeSDK(
    language: .en,              // .en, .es, or .none
    isGPSEnabled: true,         // attach geolocation to submissions
    geolocationRequired: false, // true = fail initialization without a location fix
                                // (requires isGPSEnabled: true)
    isUpdateModelsData: true,   // refresh on-device models when newer ones exist
    accessToken: accessToken    // token minted by your backend
) { error in
    if let error {
        print("SDK init failed:", error.localizedDescription)
    } else {
        // Ready — capture flows may now be presented
    }
}
```

Check `IDentitySDK.isInitialized` before presenting a capture flow if the initialization result is not in
scope.

---

## Tracking initialization progress

Initialization logs in and fetches any missing face models. Because this SDK has no document pipeline, it
reports **fewer stages** than the Lite and Medium SDKs.

> [!IMPORTANT]
> `InitializationStage` declares cases that this flavour never emits. Do not wait on them — a readiness
> check that blocks on a stage which never fires will hang forever. The stages this SDK actually reports are
> listed below.

```swift
final class SplashViewController: UIViewController, InitializationDelegate {

    private var states: [InitializationStage: InitializationState] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        IDentitySDK.delegate = self
    }

    func updateInitialization(stage: InitializationStage, state: InitializationState) {
        states[stage] = state
        print("\(stage.rawValue): \(state.rawValue)")

        let modelDone: Set<InitializationState> = [.ok, .downloadedFromS3, .error]

        let modelStages: [InitializationStage] = [
            .faceFullRangeSparseTrainingModelLabel,
            .faceLandmarksDetectorTrainingModelLabel,
            .faceBlendshapesDetectorTrainingModelLabel,
            .passiveFaceTrainingModelLabel,
            .faceMaskTrainingModelLabel,
            .focusFaceTrainingModelLabel
        ]

        if states[.login] == .downloaded,
           modelStages.allSatisfy({ modelDone.contains(states[$0] ?? .paused) }) {
            showContinueButton()
        } else if states[.login] == .error {
            showRetry()
        }
    }
}
```

**Stages reported by the Liveness SDK (7):** `login`, `faceFullRangeSparseTrainingModelLabel`,
`faceLandmarksDetectorTrainingModelLabel`, `faceBlendshapesDetectorTrainingModelLabel`,
`passiveFaceTrainingModelLabel`, `faceMaskTrainingModelLabel`, `focusFaceTrainingModelLabel`.

This flavour has no document pipeline, so it never reports `getXsltData`,
`searchCompanyTemplateDetails`, `idCaptureTrainingModelLabel`, `classifierTrainingModelLabel`,
`docDetectionTrainingModelLabel`, `fingerprintDetectionTrainingModelLabel`, or `focusTrainingModelLabel`.

**States:** `ok`, `paused`, `downloading`, `downloaded`, `downloadingFromS3`, `downloadedFromS3`, `error`.

---

## Features

Every capture API follows the same two-phase shape:

1. **Capture** — present a flow from one of your view controllers and receive a result object.
2. **Submit** — call `finalSubmit` on that result to send it to the IDmission platform.

Splitting the two lets you review, gate, or annotate a capture before it leaves the device.

Each section below gives the exact public signature followed by a complete, runnable example — every
completion handler is written out in full.

---

### Live face check

Captures a selfie and runs passive liveness on the device.

```swift
public class func liveFaceCheck(
    from presenter: UIViewController,
    customerDataOptions: CommonCustomerDataRequest? = nil,
    options: AdditionalCustomerLiveCheckData? = nil,
    completion: @escaping LiveFaceCheckCompletion   // Result<LiveFaceCheckResult, Error>
)
```

```swift
import SelfieCaptureLiveness

IDentitySDK.liveFaceCheck(
    from: self,
    customerDataOptions: CommonCustomerDataRequest(),
    options: AdditionalCustomerLiveCheckData()
) { result in
    switch result {
    case .success(let capture):
        // capture.selfie: Selfie, capture.isFakeFace: Bool
        capture.finalSubmit { submission in
            switch submission {
            case .success(let response):
                print(response)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

---

### Enroll biometrics

Registers a customer's face so they can later be verified or identified.

```swift
public class func customerEnrollBiometrics(
    from presenter: UIViewController,
    customerDataOptions: CommonCustomerDataRequest? = nil,
    personalData: PersonalCustomerEnrollBiometricsRequestData,
    options: AdditionalCustomerEnrollBiometricRequestData,
    completion: @escaping CustomerEnrollBiometricsCompletion  // Result<CustomerEnrollBiometricsResult, Error>
)
```

```swift
import SelfieCaptureLiveness

let personalData = PersonalCustomerEnrollBiometricsRequestData(uniqueNumber: "CUST-10432")

IDentitySDK.customerEnrollBiometrics(
    from: self,
    customerDataOptions: CommonCustomerDataRequest(),
    personalData: personalData,
    options: AdditionalCustomerEnrollBiometricRequestData()
) { result in
    switch result {
    case .success(let capture):
        capture.finalSubmit { submission in
            switch submission {
            case .success(let response):
                print(response)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

`uniqueNumber` is the only required field on `PersonalCustomerEnrollBiometricsRequestData`; every other
field has a default.

---

### Customer verification

**1:1.** Confirms that the person in front of the camera is the customer they claim to be.

```swift
public class func customerVerification(
    from presenter: UIViewController,
    customerDataOptions: CommonCustomerDataRequest? = nil,
    personalData: PersonalCustomerVerifyData,
    options: AdditionalCustomerCommonData,
    completion: @escaping CustomerVerificationCompletion  // Result<CustomerVerificationResult, Error>
)
```

```swift
import SelfieCaptureLiveness

IDentitySDK.customerVerification(
    from: self,
    customerDataOptions: CommonCustomerDataRequest(),
    personalData: PersonalCustomerVerifyData(uniqueNumber: "CUST-10432"),
    options: AdditionalCustomerCommonData()
) { result in
    switch result {
    case .success(let capture):
        capture.finalSubmit { submission in
            switch submission {
            case .success(let response):
                print(response)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

---

### Identify customer

**1:N.** Finds an unknown person among the customers already enrolled. Takes no `personalData`, because the
customer is what you are trying to discover.

```swift
public class func identifyCustomer(
    from presenter: UIViewController,
    customerDataOptions: CommonCustomerDataRequest? = nil,
    options: AdditionalCustomerCommonData,
    completion: @escaping CustomerIdentifyCompletion  // Result<CustomerIdentifyResult, Error>
)
```

```swift
import SelfieCaptureLiveness

IDentitySDK.identifyCustomer(
    from: self,
    customerDataOptions: CommonCustomerDataRequest(),
    options: AdditionalCustomerCommonData()
) { result in
    switch result {
    case .success(let capture):
        capture.finalSubmit { submission in
            switch submission {
            case .success(let response):
                print(response)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

---

### Generic final submit

Escape hatch for client-specific configurations that no dedicated API covers. You supply the request
dictionary and receive the raw response.

```swift
public class func genericApiCall(
    genericDataDictionary: [String: Any],
    completion: @escaping GenericAPICompletion   // Result<[String: Any], Error>
)
```

```swift
let genericDataDictionary: [String: Any] = [
    "key": "value"
]

IDentitySDK.genericApiCall(genericDataDictionary: genericDataDictionary) { result in
    switch result {
    case .success(let response):
        print(response)
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

---

`CommonCustomerDataRequest` and the various `Additional…Data` option structs carry the per-transaction
settings; every field has a default, so `AdditionalCustomerLiveCheckData()` is a valid starting point.
The SDK builds the request XML for you — you never construct it by hand.
## Localization

The SDK ships English and Spanish UI strings.

Set it when you initialize:

```swift
IDentitySDK.initializeSDK(
    language: .es,
    isGPSEnabled: true,
    geolocationRequired: false,
    isUpdateModelsData: true,
    accessToken: accessToken
) { error in
    if let error {
        print("SDK init failed:", error.localizedDescription)
    } else {
        // Ready
    }
}
```

Or change it at any point afterwards:

```swift
Language.current = .es
```

`Language.none` disables the SDK's own string localization.

---

## Security controls

The SDK detects screenshots and screen recording, and scans loaded images for hooking and instrumentation
frameworks. Both protections are enabled by default once `initializeSDK` completes.

```swift
// Screenshot and screen-recording monitoring. Enabled by default after initializeSDK.
IDentitySDK.setScreenSecurityEnabled(true)

// The automatic blur overlay applied when screen recording is detected. Enabled by default.
IDentitySDK.isScreenRecordingEnabled(true)

// Names of your own security frameworks that would otherwise be flagged as
// instrumentation. Set this BEFORE calling initializeSDK.
IDentitySDK.allowedSecurityFrameworks = ["MyJailbreakDetector"]
```

> [!NOTE]
> Despite the `is` prefix, `isScreenRecordingEnabled(_:)` is a setter, not a query — it takes a `Bool` and
> returns nothing.

If your app bundles a legitimate anti-tamper or jailbreak-detection framework, add its name to
`allowedSecurityFrameworks` **before** initializing. The SDK's hook detection would otherwise flag it as a
false positive.

`setDevelopmentRelaxationSecret(_:)` relaxes selected runtime integrity checks for debugging. **Never ship an
app that calls it.** Ask IDmission support before using it.

---

## Diagnostics

```swift
IDentitySDK.version                        // SDK version string
IDentitySDK.isInitialized                  // Bool
IDentitySDK.modelVersions                  // [String: String] of on-device model versions
IDentitySDK.areModelsAlreadyDownloadedAndValid
IDentitySDK.requestID                      // unique id for the current request
```

Include `IDentitySDK.version` and `IDentitySDK.requestID` in any support ticket — they let IDmission trace a
transaction end to end.

---

## Framework sizes

Measured at **11.1.13**. Uncompressed on-disk size of the `arm64` device slice. **Not** App Store download size — thinning and
compression reduce the delivered figure substantially.

| Framework | Size | Included with |
|:---|---:|:---|
| `IDentityLivenessSDK` | 15.5 MB | `IDentityLivenessSDK` |
| `SelfieCaptureLiveness` | 1.2 MB | `IDentityLivenessSDK` |
| `IDentityLivenessModels` | 11.5 MB | `IDentityLivenessModels` (optional) |

Required products total **16.7 MB**. Omit `IDentityLivenessModels` to save 11.5 MB of app binary at the cost
of a model download on first run.

---

## Versioning and releases

Releases are published as Git tags of the form `MAJOR.MINOR.PATCH` — for example `11.1.13`. Pin with
`from: "11.1.13"` to accept compatible updates, or pin `.exact("11.1.13")` if your release process requires a
frozen dependency graph.

The three IDmission SPM packages are versioned in lockstep. If you integrate more than one, use the same
version across all of them.

### Release notes

#### 11.1.13
- Added customizable properties.
- Reduced overall SDK package size.
- Introduced a timeout timer for capture to improve user flow and prevent indefinite waiting.

---

## Troubleshooting

| Symptom | Cause and fix |
|:---|:---|
| `no such module 'IDentityLivenessSDK'` when building for the simulator on an Apple Silicon Mac | No `arm64` simulator slice. Build for a physical device, or set `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`. See [Apple Silicon simulators](#apple-silicon-simulators). |
| `Library not loaded: @rpath/IDentityLivenessSDK.framework/…` at launch | The binary target is not embedded. Confirm the product appears under **General → Frameworks, Libraries, and Embedded Content** with **Embed & Sign**. |
| Capture screens present, but every submission fails | The SDK was not initialized, or the access token has expired. Check `IDentitySDK.isInitialized` and mint a fresh token. |
| Initialization never completes | A model stage is stuck. Log every `updateInitialization` callback and check network access to the IDmission model CDN. |
| Camera view is black | Missing `NSCameraUsageDescription`, or camera permission was denied in Settings. |
| Looking for `idValidation` or `autofill` | Not available here — this SDK is face-only. Use the Lite or Medium SDK for documents. |
| App Store upload rejected for an invalid bundle | Ensure only the products you use are linked, and that they are embedded and signed rather than merely linked. |
| Duplicate symbols with TensorFlow Lite | You added the CocoaPods dependencies from the older integration guide. The Swift Package needs none — remove them. |

---

## Support

| | |
|:---|:---|
| Technical support | <support@idmission.com> |
| Sales and licensing | <sales@idmission.com> |
| Privacy | <privacyteam@idmission.com> |
| Web | <https://www.idmission.com> |

Sample application: [LivenessSDK2Sample](https://github.com/Idmission-LLC/LivenessSDK2Sample)

When reporting an issue, include your SDK version, iOS version, device model, the `requestID` of a failing
transaction, and the `updateInitialization` log if the problem occurs at startup.

---

## Licence

Copyright © 2026 IDmission, LLC. All rights reserved.

Proprietary and confidential. Use requires a written commercial agreement with IDmission. See
[LICENSE](LICENSE) for the full terms, including the third-party open-source notices that apply to components
embedded in the SDK.
