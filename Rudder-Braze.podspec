Pod::Spec.new do |s|
  s.name             = 'Rudder-Braze'
  s.version          = '1.0.0-beta.1'
  s.summary          = 'Privacy and Security focused Segment-alternative. Braze Native SDK integration support.'

  s.description      = <<-DESC
Rudder is a platform for collecting, storing and routing customer event data to dozens of tools. Rudder is open-source, can run in your cloud environment (AWS, GCP, Azure or even your data-centre) and provides a powerful transformation framework to process your event data on the fly.
                       DESC

  s.homepage         = 'https://github.com/rudderlabs/rudder-integration-braze-ios'
  s.license          = { :type => "Apache", :file => "LICENSE" }
  s.author           = { 'RudderStack' => 'raj@rudderlabs.com' }
  s.source           = { :git => 'https://github.com/rudderlabs/rudder-integration-braze-ios.git', :commit => '378d4c6f0a8b00df6291563a19e3b213a4ac06d4' }
  s.platform         = :ios, "9.0"

  s.source_files = 'Rudder-Braze/Classes/**/*'

  s.dependency 'Rudder'
  s.dependency 'Appboy-iOS-SDK', '3.27.0-beta1'
end
