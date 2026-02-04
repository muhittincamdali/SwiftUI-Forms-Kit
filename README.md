<p align="center">
  <img src="Assets/logo.png" alt="SwiftUI Forms Kit" width="200"/>
</p>

<h1 align="center">SwiftUI Forms Kit</h1>

<p align="center">
  <strong>📋 Advanced form builder for SwiftUI with validation & 30+ field types</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift"/>
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS"/>
</p>

---

## Features

| Feature | Description |
|---------|-------------|
| 📝 **30+ Fields** | Text, date, picker, slider... |
| ✅ **Validation** | Built-in & custom rules |
| 🎨 **Styling** | Customizable appearance |
| ♿ **Accessible** | VoiceOver support |
| 🌍 **i18n** | Localization ready |

## Quick Start

```swift
import SwiftUIFormsKit

struct SignupForm: View {
    @FormState var form = SignupFormData()
    
    var body: some View {
        Form {
            FormField("Name", $form.name)
                .validation(.required, .minLength(2))
            
            FormField("Email", $form.email)
                .validation(.required, .email)
            
            FormField("Password", $form.password)
                .validation(.required, .minLength(8))
                .secure()
            
            FormField("Birth Date", $form.birthDate)
                .fieldType(.datePicker)
                .validation(.required, .age(min: 18))
        }
        .onSubmit {
            if form.isValid {
                submit()
            }
        }
    }
}
```

## Field Types

```swift
// Text
FormField("Name", $name)
FormField("Bio", $bio).multiline()
FormField("Password", $password).secure()

// Numbers
FormField("Age", $age).fieldType(.number)
FormField("Price", $price).fieldType(.currency)

// Selection
FormField("Country", $country).fieldType(.picker(countries))
FormField("Rating", $rating).fieldType(.slider(1...5))

// Date & Time
FormField("Date", $date).fieldType(.datePicker)
FormField("Time", $time).fieldType(.timePicker)

// Other
FormField("Accept Terms", $accepted).fieldType(.toggle)
FormField("Photo", $image).fieldType(.imagePicker)
```

## Validation

```swift
// Built-in rules
.validation(.required)
.validation(.email)
.validation(.minLength(8))
.validation(.maxLength(100))
.validation(.pattern(/^\d{5}$/))

// Custom rule
.validation(.custom { value in
    value.contains("@") ? nil : "Must contain @"
})
```

## Styling

```swift
FormField("Name", $name)
    .style(FormFieldStyle(
        labelColor: .secondary,
        borderColor: .blue,
        cornerRadius: 12
    ))
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License
