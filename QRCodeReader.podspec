Pod::Spec.new do |s|
  s.name             = 'QRCodeReader'
  s.version          = '1.0.1'
  s.summary          = 'iOS framework contain core view elements and logic component for work with QR codes.'
  s.homepage         = 'https://github.com/TouchInstinct/QRCodeReader-ios'
  
  s.license          = 'Apache License, Version 2.0'
  s.author           = 'Touch Instinct'
  s.source           = { :git => 'https://github.com/TouchInstinct/QRCodeReader-ios.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'
  
  s.swift_version = '5.0'
  s.source_files = 'QRCodeReader/Classes/**/*'
  s.frameworks = 'AVFoundation'
end
