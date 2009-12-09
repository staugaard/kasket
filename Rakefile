require 'rubygems'
require 'rake'
require 'lib/kasket'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "kasket"
    gem.version = Kasket::Version::STRING
    gem.summary = %Q{A write back caching layer on active record}
    gem.description = %Q{puts a cap on your queries}
    gem.email = "mick@staugaard.com"
    gem.homepage = "http://github.com/staugaard/kasket"
    gem.authors = ["Mick Staugaard", "Eric Chapweske"]
    gem.add_dependency('activerecord', '>= 2.3.4')
    gem.add_dependency('activesupport', '>= 2.3.4')
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.add_development_dependency "mocha", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.rcov_opts << "--exclude \"test/*,gems/*,/Library/Ruby/*,config/*\" --rails" 
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "kasket #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
