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
  pod '1PasswordExtension', '~> 1.8.5'
  # Potential
  # pod 'DATAStack',          '~> 6'
  # pod 'DATASource',         '~> 6'
  # pod 'Sync',               '~> 2'
end

# Rx
def rx_pods
  pod 'RxSwift',            '~> 4.0'
  pod 'RxCocoa',            '~> 4.0'
  pod 'RxDataSources',      '~> 3.0'
  pod "RxSwiftExt",         '~> 3.0'
  # pod 'RxAlamofire',        '~> 4.0'
  # pod "RxCoreData",         '~> 0.4.0'
end

# Testing
def test_pods
  pod 'RxBlocking',         '~> 4.0'
  pod 'RxTest',             '~> 4.0'
end

target 'Mobile' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Mobile
  basic_pods
  rx_pods

  target 'MobileTests' do
    inherit! :search_paths
    # Pods for testing
    # test_pods
  end

  # Enable RxSwift.Resources for debugging
  # post_install do |installer|
  #   installer.pods_project.targets.each do |target|
  #     if target.name == 'RxSwift'
  #       target.build_configurations.each do |config|
  #         if config.name == 'Debug'
  #           config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['-D', 'TRACE_RESOURCES']
  #         end
  #       end
  #     end
  #   end
  # end

end
