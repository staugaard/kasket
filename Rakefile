require 'bundler/setup'
require 'bundler/gem_tasks'
require 'appraisal'
require 'wwtd/tasks'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => ['appraisal:cleanup', 'appraisal:install', :wwtd]
