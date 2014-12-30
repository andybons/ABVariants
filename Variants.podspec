Pod::Spec.new do |spec|
  spec.name     = 'Variants'
  spec.version  = '1.0.2'
  spec.license  = { :type => "MIT", :file => "LICENSE" }
  spec.summary  = 'Experiments/Mods system for iOS and OS X'
  spec.homepage = 'https://github.com/andybons/ABVariants'
  spec.authors  = { 'Andrew Bonventre' => 'andybons@gmail.com' }
  spec.source   = { :git => 'https://github.com/andybons/ABVariants.git', :tag => "1.0.2" }
  spec.requires_arc = true
  spec.ios.deployment_target = '6.0'
  spec.osx.deployment_target = '10.8'
  spec.source_files = 'ABVariants/*.{h,m}'
  spec.frameworks = 'Foundation'
end
