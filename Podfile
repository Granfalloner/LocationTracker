platform :ios, '11.0'

target 'LTKit' do
  use_frameworks!

  pod 'SwiftLint', '~> 0.29'

  pod 'RxSwift', '~> 4.4'
  pod 'RxSwiftExt', '~> 3.4'

  target 'LTKitTests' do
    inherit! :search_paths
  end
end

target 'LocationTracker' do
  use_frameworks!

  pod 'RxCocoa', '~> 4.4'

  target 'LocationTrackerTests' do
    inherit! :search_paths
  end

  target 'LocationTrackerUITests' do
    inherit! :search_paths
  end
end
