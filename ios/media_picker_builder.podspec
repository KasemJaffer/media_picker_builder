#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'media_picker_builder'
  s.version          = '0.0.1'
  s.summary          = 'A plugin that returns multimedia picker data such as folders and its content path list to build your own custom flutter picker'
  s.description      = <<-DESC
A plugin that returns multimedia picker data such as folders and its content path list to build your own custom flutter picker
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
	s.swift_version = '5.0'

  s.ios.deployment_target = '12.0'
end

