# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'TwitterTest' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TwitterTest
  pod 'SimpleAuth/Twitter'
  pod 'SimpleAuth/TwitterWeb'
  pod 'RxSwift',    '~> 3.0'
  pod 'RxCocoa',    '~> 3.0'
  pod 'SDWebImage', '~>3.8'
  pod 'Kanna', '~> 2.1.0'
end
post_install do |_|
    work_dir = Dir.pwd
    file_name = "#{work_dir}/Pods/Target\ Support\ Files/SimpleAuth/SimpleAuth.xcconfig"
    config = File.read(file_name)
    new_config = config.gsub(/HEADER_SEARCH_PATHS = "/, 'HEADER_SEARCH_PATHS = "${PODS_ROOT}" "')
                             File.open(file_name, 'w') { |file| file << new_config }
end
