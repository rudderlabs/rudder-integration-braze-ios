require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

appboy_sdk_version = '4.4.2'

Pod::Spec.new do |s|
  s.name             = 'Rudder-Braze'
  s.version          = package['version']
  s.summary          = 'Privacy and Security focused Segment-alternative. Braze Native SDK integration support.'

  s.description      = <<-DESC
Rudder is a platform for collecting, storing and routing customer event data to dozens of tools. Rudder is open-source, can run in your cloud environment (AWS, GCP, Azure or even your data-centre) and provides a powerful transformation framework to process your event data on the fly.
                       DESC

  s.homepage         = 'https://github.com/rudderlabs/rudder-integration-braze-ios'
  s.license          = { :type => "Apache", :file => "LICENSE" }
  s.author           = { 'RudderStack' => 'raj@rudderlabs.com' }
  s.source           = { :git => 'https://github.com/rudderlabs/rudder-integration-braze-ios.git', :tag => "v#{s.version}" }
  s.platform         = :ios, "9.0"

  ## Ref: https://github.com/CocoaPods/CocoaPods/issues/10065
  ## s.pod_target_xcconfig = {
  ##   'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  ## }
  ## s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.source_files = 'Rudder-Braze/Classes/**/*'

  s.dependency 'Rudder', '~> 1.0'

  if defined?($AppboySDKVersion)
    Pod::UI.puts "#{s.name}: Using user specified Appboy SDK version '#{$AppboySDKVersion}'"
    appboy_sdk_version = $AppboySDKVersion
  else
    Pod::UI.puts "#{s.name}: Using default Appboy SDK version '#{appboy_sdk_version}'"
  end

  s.dependency 'Appboy-iOS-SDK', appboy_sdk_version
end
