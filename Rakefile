require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'appraisal'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default do
  sh "rake appraisal:install && rake appraisal test"
end
