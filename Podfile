# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Basic
def basic_pods
  pod 'Alamofire',          '~> 4.4'
  pod 'CodableAlamofire'
  pod 'SwiftyJSON'
  pod 'KeychainAccess'
  pod 'PKHUD',              '~> 5.0'
  pod 'SwiftyBeaver'
  pod '1PasswordExtension', :git => 'https://github.com/AgileBits/onepassword-app-extension.git', :branch => 'new/ios10'
  # Rx
  pod 'RxSwift',            '~> 4.0'
  pod 'RxCocoa',            '~> 4.0'
  pod 'RxDataSources',      '~> 3.0'
  pod "RxSwiftExt",         '~> 3.0'
  # pod 'RxAlamofire',        '~> 4.0'
  # pod "RxCoreData",         '~> 0.4.0'
  # A
  # pod 'DATAStack',        '~> 6'
  # pod 'DATASource',       '~> 6'
  # pod 'Sync',             '~> 2'
  # B
  # pod 'ObjectMapper',     '~> 2.2'
  # pod 'AlamofireObjectMapper', '~> 4.0'
  #
  # pod 'ChameleonFramework/Swift3'
end

# def test_pods
#   pod 'RxBlocking',         '~> 4.0'
#   pod 'RxTest',             '~> 4.0'
# end

target 'Mobile' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Mobile
  basic_pods

  target 'MobileTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

# post_install do |installer|
#     installer.pods_project.targets.each do |target|
#         target.build_configurations.each do |config|
#             config.build_settings['SWIFT_VERSION'] = '3.2'
#         end
#     end
# end