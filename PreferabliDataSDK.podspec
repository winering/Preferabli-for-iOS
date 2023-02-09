Pod::Spec.new do |spec|
  spec.name         = "WineRingSDK"
  spec.version      = "1.0.0"
  spec.summary      = "This is the Wine Ring iOS SDK."
  spec.homepage     = "https://github.com/winering/Wine-Ring-for-iOS.git"
  spec.license = { :type => 'RingIT, Inc.', :text => <<-LICENSE
      Copyright 2020
      Permission is granted to use this SDK to customers of RingIT, Inc.
    LICENSE
  }
  spec.author             = { "RingIT, Inc." => "info@winering.com" }
  spec.platform     = :ios, "11.0"
  spec.ios.deployment_target = '11.0'
  spec.source       = { :git => 'https://github.com/winering/Wine-Ring-for-iOS.git' }
  spec.ios.vendored_frameworks = 'WineRingSDK.framework'
  spec.dependency 'TTGSnackbar'
  spec.dependency 'Kingfisher'
  spec.dependency 'Alamofire', '4.9.1'
  spec.dependency 'MagicalRecord'
  spec.dependency 'SwiftEventBus'
  spec.dependency 'XLPagerTabStrip'
  spec.dependency 'RPCircularProgress'
  spec.dependency 'SideMenu'
  spec.dependency 'GooglePlaces'
  spec.exclude_files = "Classes/Exclude"
  spec.swift_version = "5.0"
end
