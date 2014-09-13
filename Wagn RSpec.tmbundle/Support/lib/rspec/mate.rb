# This is based on Florian Weber's TDDMate

ENV['TM_PROJECT_DIRECTORY'] ||= File.dirname(ENV['TM_FILEPATH'])

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')

require 'rspec/mate/runner'
require 'rspec/mate/options'
require 'rspec/mate/switch_command'

# TODO: move to Options
def bundler_option?
  RSpec::Mate::Options['--bundler']
end

# TODO: move to Options
def skip_bundler_option?
  RSpec::Mate::Options['--skip-bundler']
end

def wagn_rspec?
  ENV['TM_RSPEC_MODE'] == 'core'
end

def deck_rspec?
  ENV['TM_RSPEC_MODE'] == 'deck'
end

def find_rspec_lib
  candidate_rspec_lib_paths = Dir.glob(
    File.join(
      ENV['TM_PROJECT_DIRECTORY'],
      'vendor',
      '{plugins,gems}',
      '{rspec,rspec-core}{,-[0-9]*}',
      'lib'
    )
  )

  if ENV['TM_RSPEC_HOME']
    candidate_rspec_lib_paths << File.join(
      ENV['TM_RSPEC_HOME'],
      'lib'
    )
  end

  rspec_lib = candidate_rspec_lib_paths.detect do |dir|
    File.exist?(dir)
  end
end

def gemfile?
  File.exist?(File.join(ENV['TM_PROJECT_DIRECTORY'], 'Gemfile'))
end

def use_binstub?
  # Using binstub means we need to look at the Gemfile to determine RSpec version,
  # so having a Gemfile is mandatory.
  return true
  gemfile? && File.exist?(File.join(ENV['TM_PROJECT_DIRECTORY'], 'bin', 'rspec'))
end

def use_bundler?
  bundler_option? || (gemfile? && !skip_bundler_option?)
end

def rspec_version
  @rspec_version  ||=  begin
    if wagn_rspec? or deck_rspec?
      "3.0.0"
    elsif use_binstub?
      specs = Bundler::LockfileParser.new(Bundler.read_file(File.join(ENV['TM_PROJECT_DIRECTORY'], 'Gemfile.lock'))).specs
      specs.detect{ |s| s.name == "rspec-core" }.version.to_s
    elsif defined?(RSpec::Core)
      RSpec::Core::Version::STRING
    else
      raise "Could not determine RSpec version. Please report at https://github.com/rspec/rspec-tmbundle/issues"
    end
  end
end

def rspec3?
  rspec_version.start_with?("3.")
end

rspec_lib = nil

if use_binstub? || use_bundler?
  require "rubygems"
  require "bundler"

  Bundler.setup if use_bundler?
else
  rspec_lib = find_rspec_lib

  if rspec_lib
    $LOAD_PATH.unshift(rspec_lib)
  end
end

require 'rspec/core' unless use_binstub? or wagn_rspec? or deck_rspec?
