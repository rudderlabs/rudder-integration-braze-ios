Pod::Spec.new do |s|
  s.name             = 'Rudder-Braze'
  s.version          = '1.0.0-beta.2'
  s.summary          = 'Privacy and Security focused Segment-alternative. Braze Native SDK integration support.'

  s.description      = <<-DESC
Rudder is a platform for collecting, storing and routing customer event data to dozens of tools. Rudder is open-source, can run in your cloud environment (AWS, GCP, Azure or even your data-centre) and provides a powerful transformation framework to process your event data on the fly.
                       DESC

  s.homepage         = 'https://github.com/rudderlabs/rudder-integration-braze-ios'
  s.license          = { :type => "Apache", :file => "LICENSE" }
  s.author           = { 'RudderStack' => 'raj@rudderlabs.com' }
  s.source           = { :git => 'https://github.com/rudderlabs/rudder-integration-braze-ios.git', :commit => '76309c4f21495e6bfdbf40f6c03a0d710febd2ba' }
  s.platform         = :ios, "9.0"
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',

    # Skipping this architecture to pass Pod validation since we explicitly remove simulator `arm64` ARCH to do lipo later
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.source_files = 'Rudder-Braze/Classes/**/*'

  s.dependency 'Rudder'
  s.dependency 'Appboy-iOS-SDK', '3.27.0-beta2'
end
