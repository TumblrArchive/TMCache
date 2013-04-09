Pod::Spec.new do |s|
  s.name          = 'TMPettyCache'
  s.version       = '1.0.0'
  s.source_files  = 'TMPettyCache/*.{h,m}'
  s.homepage      = 'http://tumblr.github.com/TMPettyCache/'
  s.summary       = 'Hybrid in-memory/on-disk cache for iOS and OS X.'
  s.authors       = { 'Justin Ouellette' => 'jstn@tumblr.com' }
  s.source        = { :git => 'https://github.com/tumblr/tumblr-ios-cache', :tag => "#{s.version}" }
  s.license       = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.weak_frameworks   = 'UIKit'
  s.osx.weak_frameworks   = 'AppKit'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.documentation = {
    :html => 'http://tumblr.github.com/TMPettyCache/docs/html',
    :appledoc => [
      '--company-id', 'com.tumblr',
      '--project-name', 'TMPettyCache',
      '--project-company', 'Tumblr',
      '--project-version', '1.0.0',
      '--docset-min-xcode-version', '4.3',
      '--docset-bundle-name', '%PROJECT',
      '--docset-bundle-id', '%COMPANYID.%PROJECTID',
      '--docset-bundle-filename', '%COMPANYID.%PROJECTID-%VERSIONID.docset',
      '--docset-feed-name', '%PROJECT',
      '--docset-feed-url', 'http://tumblr.github.com/TMPettyCache/docs/publish/%DOCSETATOMFILENAME',
      '--docset-package-url', 'http://tumblr.github.com/TMPettyCache/docs/publish/%DOCSETPACKAGEFILENAME',
      '--docset-fallback-url', 'http://tumblr.github.com/TMPettyCache/docs/html/',
      '--ignore', 'example',
      '--ignore', 'docs',
      '--ignore', '*.m',
      '--no-repeat-first-par',
      '--explicit-crossref',
      '--clean-output',
      '--keep-undocumented-objects',
      '--keep-undocumented-members',
      '--no-search-undocumented-doc',
      '--no-warn-undocumented-member'
    ]
  }
end
