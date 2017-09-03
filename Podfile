# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'To-Do Widget' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for To-Do Widget
  pod 'SwiftDate', '~> 4.0'

end

target 'ToDoCoreDataCloudKit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'SwiftDate', '~> 4.0'
  
  # Pods for ToDoCoreDataCloudKit

  target 'ToDoCoreDataCloudKitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'Todododo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Todododo
  pod 'MGSwipeTableCell'
  pod 'Mixpanel-swift'
  pod 'SwiftDate', '~> 4.0'
  pod 'ChameleonFramework/Swift'
  pod 'LicensesKit'

  target 'TodododoTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'SwiftDate', '~> 4.0'

  end

  target 'TodododoUITests' do
    inherit! :search_paths
    # Pods for testing
    pod 'SwiftDate', '~> 4.0'

  end

end

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-Todododo/Pods-Todododo-acknowledgements.plist', 'Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
