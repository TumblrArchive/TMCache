Pod::Spec.new do |s|
  s.name          = 'TMPettyCache'
  s.version       = '1.0.0'
  s.source_files  = 'TMPettyCache/*.{h,m}'
  s.homepage      = 'http://wwww.tumblr.com/'
  s.summary       = 'Hybrid in-memory/on-disk cache for iOS and OS X.'
  s.authors       = { 'Justin Ouellette' => 'justin@tumblr.com' }
  s.source        = { :git => 'https://github.com/tumblr/tumblr-ios-cache', :tag => "#{s.version}" }
  s.license       = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.weak_frameworks   = 'UIKit'
  s.osx.weak_frameworks   = 'AppKit'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
