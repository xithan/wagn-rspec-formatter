if defined?(RSpec)
  bundle_patterns = [%r{^/tmp/textmate-command}, %r{/.gem/}, %r{/format.rb}]
  #bundle_patterns << %r{/RSpec\.tmbundle/} unless ENV['TM_PROJECT_DIRECTORY'].include?("RSpec.tmbundle")
  if RSpec.configuration.respond_to?(:backtrace_exclusion_patterns)
    RSpec.configuration.backtrace_exclusion_patterns += bundle_patterns
  elsif RSpec.configuration.respond_to?(:backtrace_clean_patterns)
    RSpec.configuration.backtrace_clean_patterns += bundle_patterns
  end
end
