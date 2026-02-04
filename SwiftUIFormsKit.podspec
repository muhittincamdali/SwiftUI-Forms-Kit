Pod::Spec.new do |s|
  s.name             = 'SwiftUIFormsKit'
  s.version          = '1.0.0'
  s.summary          = 'Form building components for SwiftUI with validation.'
  s.description      = 'SwiftUIFormsKit provides form building components with validation, dynamic fields, and custom styling.'
  s.homepage         = 'https://github.com/muhittincamdali/SwiftUI-Forms-Kit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Muhittin Camdali' => 'contact@muhittincamdali.com' }
  s.source           = { :git => 'https://github.com/muhittincamdali/SwiftUI-Forms-Kit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'Foundation', 'SwiftUI'
end
