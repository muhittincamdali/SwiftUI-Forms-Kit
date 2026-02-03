<div align="center">

# 📋 SwiftUI-Forms-Kit

**Advanced form builder for SwiftUI with validation & 30+ field types**

[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-Compatible-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## ✨ Features

- 📋 **30+ Field Types** — Text, date, picker, slider, etc.
- ✅ **Validation** — Built-in & custom rules
- 🎨 **Customizable** — Full styling control
- 📱 **Adaptive** — iOS, macOS, visionOS
- 🔄 **Two-Way Binding** — Automatic state sync

---

## 🚀 Quick Start

```swift
import SwiftUIFormsKit

struct SignupForm: View {
    @FormState var form = SignupModel()
    
    var body: some View {
        FormView {
            TextField("Name", text: $form.name)
                .validate(.required)
            
            EmailField("Email", text: $form.email)
            
            PasswordField("Password", text: $form.password)
                .validate(.minLength(8))
            
            DatePicker("Birthday", selection: $form.birthday)
            
            SubmitButton("Sign Up") {
                // Submit action
            }
        }
    }
}
```

---

## 📄 License

MIT • [@muhittincamdali](https://github.com/muhittincamdali)
