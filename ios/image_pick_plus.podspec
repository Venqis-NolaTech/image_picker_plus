#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
    s.name             = 'image_picker_plus'
    s.version          = '0.5.7'
    s.summary          = 'A Flutter plugin for customization of the gallery display or even camera and video.'
    s.description      = <<-DESC
  A Flutter plugin for customization of the gallery display or even camera and video.
  Downloaded by pub (not CocoaPods).
                         DESC
    s.homepage         = 'https://github.com/flutter/packages'
    s.license          = { :type => 'BSD', :file => '../LICENSE' }
    s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
    s.source           = { :http => 'https://github.com/flutter/packages/tree/main/packages/image_picker_plus' }
    s.documentation_url = 'https://pub.dev/packages/image_picker_plus'
    s.source_files = 'Classes/**/*.{h,m}'
    s.public_header_files = 'Classes/**/*.h'
    s.dependency 'Flutter'
    s.platform = :ios, '11.0'
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  end
  