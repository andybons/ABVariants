Pod::Spec.new do |s|
  s.name     = 'ABVariants'
  s.version  = '1.0'
  s.license  = 'MIT'
  s.summary  = 'Experiments/Mods system for iOS and OS X'
  s.homepage = 'https://github.com/andybons/ABVariants'
  s.authors  = { 'Andrew Bonventre' => 'andybons@gmail.com' }
  s.source   = { :git => 'https://github.com/andybons/ABVariants.git', :tag => "1.0" }
  s.requires_arc = true

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.public_header_files = 'ABVariants/*.h'
  s.source_files = 'ABVariants/ABVariants.h'
end
