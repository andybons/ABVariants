Pod::Spec.new do |spec|
  spec.name     = 'Variants'
  spec.version  = '0.1'
  spec.license  = 'MIT'
  spec.summary  = 'Experiments/Mods system for iOS and OS X'
  spec.homepage = 'https://github.com/andybons/ABVariants'
  spec.authors  = { 'Andrew Bonventre' => 'andybons@gmail.com' }
  spec.source   = { :git => 'https://github.com/andybons/ABVariants.git', :tag => "1.0" }
  spec.requires_arc = true
  spec.source_files = 'ABVariants/*.{h,m}'
  spec.frameworks = 'Foundation'
end
