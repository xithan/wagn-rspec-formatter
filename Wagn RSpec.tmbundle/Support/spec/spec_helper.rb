require 'simplecov'

SimpleCov.start do
  add_filter '/converage/'
  add_filter '/fixtures/'
  add_filter '/spec/'
end

ENV['TM_PROJECT_DIRECTORY'] ||= '.'

require 'stringio'
require 'rspec/mate'
require 'rspec/core'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234

  # Makes runner specs go forever with certain seeds (e.g. --seed 6871),
  # disabled until the runner will run specs in a subshell. Ref:
  # https://github.com/elia/rspec.tmbundle/commit/92bd792d813f79ffec8484469aa9ce3c7872382b#commitcomment-7325726
  # config.order = 'random'
end
