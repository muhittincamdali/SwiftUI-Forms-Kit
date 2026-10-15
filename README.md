<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Components/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Components/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Components/main/.github/brand/banner-light.svg" alt="SwiftUI Components: Ready-made SwiftUI views for iOS and macOS: buttons, cards, charts, forms and more."></picture></p>

<p align="center"><a href="README.md">English</a> · <a href="#türkçe">Türkçe</a></p>

# SwiftUI-Forms-Kit has moved

This project now lives in [SwiftUI-Components](https://github.com/muhittincamdali/SwiftUI-Components).
This repository is archived and will not receive updates.

The form code was folded into two modules of SwiftUI Components:

- [Forms](https://github.com/muhittincamdali/SwiftUI-Components/tree/main/Sources/SwiftUIComponents/Forms):
  form fields, multi-step forms and `SchemaForm`, which renders a form from a JSON schema.
- [Validation](https://github.com/muhittincamdali/SwiftUI-Components/tree/main/Sources/SwiftUIComponents/Validation):
  composable validators, async validation, schema validation and step flows.

The code was reworked while it was merged, so type names and initializers differ from this
repository's `SwiftUIFormsKit` target. Read the modules and their
[documentation](https://muhittincamdali.github.io/SwiftUI-Components/documentation/swiftuicomponents/)
before you migrate.

## Install the new package

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftUI-Components.git", from: "2.1.0")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "SwiftUIComponents", package: "SwiftUI-Components")
    ])
]
```

Requires iOS 17+ or macOS 14+ and Swift 6.2+.

## Türkçe

**Bu proje artık [SwiftUI-Components](https://github.com/muhittincamdali/SwiftUI-Components) içinde.**
Bu depo arşivlendi ve güncellenmeyecek.

Form kodu, SwiftUI Components paketinin iki modülüne taşındı:

- [Forms](https://github.com/muhittincamdali/SwiftUI-Components/tree/main/Sources/SwiftUIComponents/Forms):
  form alanları, çok adımlı formlar ve JSON şemasından form çizen `SchemaForm`.
- [Validation](https://github.com/muhittincamdali/SwiftUI-Components/tree/main/Sources/SwiftUIComponents/Validation):
  birleştirilebilir doğrulayıcılar, asenkron doğrulama, şema doğrulama ve adım akışları.

Kod taşınırken yeniden düzenlendi; tür adları ve başlatıcılar bu depodaki `SwiftUIFormsKit`
hedefinden farklıdır. Geçiş yapmadan önce modülleri ve
[belgeleri](https://muhittincamdali.github.io/SwiftUI-Components/documentation/swiftuicomponents/) okuyun.

Kurulum için yukarıdaki Swift Package Manager satırlarını kullanın. iOS 17+ veya macOS 14+ ve
Swift 6.2+ gerekir.
