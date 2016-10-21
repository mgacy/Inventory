# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Basic
def basic_pods
  pod 'Alamofire', '~> 4.0'
  pod 'SwiftyJSON'
  pod 'KeychainAccess'
end

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
