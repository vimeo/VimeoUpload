xcode_summary.ignored_files = 'Pods/*'
Dir.glob('build/reports/errors-*.json') do |result|
    xcode_summary.report result
end
markdown "See build details on [CircleCI](#{ENV['CIRCLE_BUILD_URL']})"