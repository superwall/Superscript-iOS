Pod::Spec.new do |s|
  s.name             = "Superscript"
  s.version          = "1.0.2"
  s.summary      = "A Common Expression Language evaluator used in SuperwallKit for iOS"
  s.description  = "The iOS package for Superwall's Common Expression Language evaluator built with Rust"
  s.homepage         = "https://github.com/superwall/Superscript-iOS"
  s.license      =  { :type => "MIT", :text => <<-LICENSE
    MIT License

    Copyright (c) 2024 Superwall

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

      The above copyright notice and this permission notice shall be included in all
      copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
      SOFTWARE.
      LICENSE
  }
  s.author       = { "Jake Mor" => "jake@superwall.com" }
  s.source       = { :git => "https://github.com/superwall/Superscript-iOS.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "13.0"
  s.swift_versions = ["5.5"]

  s.source_files = "Sources/**/*.{swift}"
  s.requires_arc = true

  s.vendored_frameworks = "Frameworks/libcel.xcframework"
end
