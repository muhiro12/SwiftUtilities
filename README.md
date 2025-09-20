# SwiftUtilities

Small, focused utilities for Swift apps, organized as extensions for
Foundation, SwiftUI, and SwiftData. Includes date and calendar helpers,
string normalization, collection conveniences, layout scales, and a few
testing-friendly utilities.

## Platforms

- iOS 17+
- macOS 14+
- Swift 6.2 (SwiftPM package)

## Installation

Add the package in Xcode or with Swift Package Manager.

```swift
// In Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftUtilities.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["SwiftUtilities"]
    )
]
```

## Highlights

- Collections: `Collection.empty`, `isNotEmpty`
- Optionals: `Optional.orEmpty`, `isNotEmpty`
- Dates: `DateFormatter.default`/`fixed`, `Date.stringValue` helpers
- Calendar: `Calendar.utc`, `endOfDay`, month/year boundaries, component shift
- Strings: `StringProtocol.normalizedContains` (half/full width, kana)
- Numbers: `Numeric.isZero`/`isNotZero`, `Decimal.isPlus`/`isMinus`
- SwiftUI: `View.hidden(_:)`, `singleLine()`, `twoLines()`
- Layout: `CGFloat.space(_:)`, `icon(_:)`, `component(_:)` (unit = 8)
- Images: `Image.init(data:)`, `UIImage.appIcon`
- SwiftData: `PersistentIdentifier.base64Encoded()/init(base64Encoded:)`,
  `PersistentModel.delete()`, `ModelContext.fetchFirst()/fetchRandom()`

## Usage

Collection and optional conveniences:

```swift
let a = [Int].empty            // []
let b: [Int]? = nil
let c = b.orEmpty              // []
let hasValues = [1, 2].isNotEmpty
```

Date and calendar utilities:

```swift
let cal = Calendar.utc
let date = Date()
let eod = cal.endOfDay(for: date)
let startMonth = cal.startOfMonth(for: date)
```

String normalization (half/full width and Hiragana/Katakana):

```swift
"ｶﾀｶﾅ".normalizedContains("カタカナ") // true
"ひらがな".normalizedContains("ヒラガナ") // true
```

Layout scales for spacing and sizes:

```swift
let padding = CGFloat.space(.m)     // 16
let iconSize = CGFloat.icon(.l)     // 40
let height = CGFloat.component(.s)  // 80
```

SwiftData helpers:

```swift
// Encode/Decode PersistentIdentifier as Base64
let base64 = try id.base64Encoded()
let restored = try PersistentIdentifier(base64Encoded: base64)
```

## Testing

This package uses SwiftTesting. Run tests with:

```bash
swift test
```

The test target mirrors `Sources/Extension` for structure clarity.

## Contributing

- Keep utilities small and cohesive.
- Prefer pure functions and side‑effect‑free extensions where possible.
- Add tests alongside new utilities using SwiftTesting.
