Pod::Spec.new do |spec|
  spec.name = "PreferabliDataSDK"
  spec.version = "1.0.0"
  spec.summary = "This is the private version of the Preferabli Data SDK for iOS."
  spec.homepage = "https://nick-docs.preferabli.com/documentation/preferablidatasdk"
  spec.license = { :type => 'RingIT, Inc.', :text => <<-LICENSE
      Copyright 2023
      Permission is granted to use this SDK to customers of RingIT, Inc.
    LICENSE
  }
  spec.author = { "RingIT, Inc." => "info@preferabli.com" }
  spec.platform = :ios, "13.0"
  spec.ios.deployment_target = '13.0'
  spec.ios.vendored_frameworks = 'PreferabliDataSDK.framework'
  spec.source = { :http => "https://s3.amazonaws.com/cdn.preferabli.com/sandbox/PreferabliDataSDK.framework.zip"}
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.swift_version = "5.0"
end
