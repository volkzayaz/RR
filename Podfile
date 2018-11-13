platform :ios, '10.0'
use_frameworks!

target 'RhythmicRebellion' do

pod 'Fabric'
pod 'Crashlytics'
pod 'ReachabilitySwift'
pod 'Starscream', '3.0.5'
pod 'Alamofire', '~> 4.7'
pod 'AlamofireImage', '~> 3.3'
pod 'SwiftValidator', :git => 'https://github.com/jpotts18/SwiftValidator.git', :branch => 'master'
pod 'MaterialTextField', '~> 1.0'
pod 'MBProgressHUD', '~> 1.1.0'
pod 'CloudTagView', '~> 3.0.0'
pod 'NSStringMask'
pod 'DownloadButton'
pod 'EasyTipView', '~> 2.0.0'

end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end
