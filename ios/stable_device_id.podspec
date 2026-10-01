#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint stable_device_id.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'stable_device_id'
  s.version          = '0.2.0'
  s.summary          = 'A device identifier that survives app updates and reinstalls.'
  s.description      = <<-DESC
Returns a UUID stored in the Keychain so it survives app updates and reinstalls.
                       DESC
  s.homepage         = 'https://pub.dev/packages/stable_device_id'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jose Cazal' => 'josecazal.1991@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'stable_device_id/Sources/stable_device_id/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'stable_device_id_privacy' => ['stable_device_id/Sources/stable_device_id/PrivacyInfo.xcprivacy']}
end
