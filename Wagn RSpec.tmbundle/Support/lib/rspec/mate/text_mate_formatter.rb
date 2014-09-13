require 'cgi'
require 'rspec/core/formatters/html_formatter'

# This formatter is only used for RSpec 3 (older RSpec versions ship their own TextMateFormatter).
module RSpec
  module Mate
    module Formatters
      class HtmlPrinterWithClickableBacktrace < RSpec::Core::Formatters::HtmlPrinter
        def make_backtrace_clickable(backtrace)
          backtrace.gsub!(/(^.*?):(\d+):(.*)/) do
            path, line, rest = $1, $2, $3
            url = "txmt://open?url=file://#{CGI::escape(File.expand_path(path))}&line=#{$2}"
            link_text = "#{path}:#{line}"
            "<a href='#{CGI.escape_html(url)}'>#{CGI.escape_html(link_text)}</a>:#{CGI.escape_html(rest)}"
          end
        end
        
        def print_example_failed(pending_fixed, description, run_time, failure_id, exception, extra_content, escape_backtrace = false)
          exception[:backtrace] = make_backtrace_clickable(exception[:backtrace])
          # Call original implementation, but pass false for `escape_backtrace`
          super(pending_fixed, description, run_time, failure_id, exception, extra_content, false)
        end
      end

      class TextMateFormatter < RSpec::Core::Formatters::HtmlFormatter
        RSpec::Core::Formatters.register self, *RSpec::Core::Formatters::Loader.formatters[superclass]

        def initialize(output)
          super
          @printer = HtmlPrinterWithClickableBacktrace.new(output)
        end
      end
    end
  end
end
