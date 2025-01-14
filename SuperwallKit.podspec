Pod::Spec.new do |s|

	s.name         = "SuperwallKit"
  s.version      = "4.0.0-beta.2"
	s.summary      = "Superwall: In-App Paywalls Made Easy"
	s.description  = "Paywall infrastructure for mobile apps :) we make things like editing your paywall and running price tests as easy as clicking a few buttons. superwall.com"

	s.homepage     = "https://github.com/superwall/Superwall-iOS"
	s.license      =  { :type => 'MIT', :text => <<-LICENSE
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
	s.source       = { :git => "https://github.com/superwall/Superwall-iOS.git", :tag => "#{s.version}" }

	s.author       = { "Jake Mor" => "jake@superwall.com" }
	s.documentation_url = "https://docs.superwall.com/"
	s.swift_versions = ['5.5']
	s.ios.deployment_target = '13.0'
	s.requires_arc = true
  s.dependency 'Superscript', '0.1.17'

  s.source_files  = "Sources/**/*.{swift}"
  s.resource_bundles = {
    'SuperwallKit' => [
      "Sources/SuperwallKit/**/*.xcassets",
      "Sources/SuperwallKit/**/*.xcdatamodeld",
      "Sources/SuperwallKit/**/*.cer",
      "Sources/SuperwallKit/**/PrivacyInfo.xcprivacy"
    ]
  }

end
