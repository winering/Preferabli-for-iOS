Pod::Spec.new do |spec|
  spec.name         = "PreferabliDataSDK"
  spec.version      = "1.0.5"
  spec.summary      = "Use this framework to integrate Preferabli's powerful preference technology into your applications."
  spec.homepage     = "https://github.com/winering/Preferabli-for-iOS"
  spec.license = { :type => 'RingIT, Inc.', :text => <<-LICENSE
      Copyright 2023
      Permission is granted to use this SDK to customers of RingIT, Inc.
    LICENSE
  }
  spec.author = { "RingIT, Inc." => "info@preferabli.com" }
  spec.platform = :ios, "13.0"
  spec.ios.deployment_target = '13.0'
  spec.source = { :git => 'https://github.com/winering/Preferabli-for-iOS' }
  spec.ios.vendored_frameworks = 'PreferabliDataSDK.framework'
  spec.dependency 'Alamofire', '4.9.1'
  spec.dependency 'MagicalRecord'
  spec.dependency 'SwiftEventBus'
  spec.dependency 'Mixpanel-swift'
  spec.exclude_files = "Classes/Exclude"
  spec.swift_version = "5.0"
end
