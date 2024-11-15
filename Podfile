platform :ios, '13.0'

source 'git@github.com:bdgroup/shared.ios.cocoaspec.git'
source 'https://github.com/CocoaPods/Specs.git'

use_frameworks! :linkage => :static

def shared_pods
  pod 'INCR_Extensions', '0.1.0'
  pod 'IncrdblSDK', '0.2.0'
end

target 'AnimationVerifier' do
    project 'AnimationVerifier.xcodeproj'
    
    shared_pods
    
    pod 'lottie-ios', '4.4.3'
    pod 'INCR_UIExtensions', '0.1.3'
end
