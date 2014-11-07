#!/usr/bin/env ruby

require 'pp'
require 'erb'
require 'pathname'

require 'rspec'
require 'rspec/core/formatters/base_text_formatter'
require 'rspec/core/formatters/snippet_extractor'
require 'rspec/core/pending'



class RSpec::Core::Formatters::Deck < RSpec::Core::Formatters::BaseTextFormatter
    RSpec::Core::Formatters.register self, :start, :example_group_started, :start_dump,
                        :example_started, :example_passed, :example_failed,
                        :example_pending, :dump_summary, :dump_failures

	include ERB::Util
							

	# Version constant
	VERSION = '2.4.0'

	# Look up the datadir falling back to a relative path (mostly for prerelease testing)
	DATADIR = begin
		dir = Gem.datadir('wagn-rspec-formatter') ||
		      Pathname( __FILE__ ).dirname.parent.parent.parent.parent +
		           'data/wagn-rspec-formatter'
		Pathname( dir )
	end

	# The base HREF used in the header to map stuff to the datadir
	BASE_HREF        = "file://#{DATADIR}/"

	# The directory to grab ERb templates out of
	TEMPLATE_DIR     = DATADIR + 'templates'

	# The page part templates
	HEADER_TEMPLATE          = TEMPLATE_DIR + 'header.rhtml'
	PASSED_EXAMPLE_TEMPLATE  = TEMPLATE_DIR + 'passed.rhtml'
	FAILED_EXAMPLE_TEMPLATE  = TEMPLATE_DIR + 'failed.rhtml'
	PENDING_EXAMPLE_TEMPLATE = TEMPLATE_DIR + 'pending.rhtml'
	PENDFIX_EXAMPLE_TEMPLATE = TEMPLATE_DIR + 'pending-fixed.rhtml'
	FOOTER_TEMPLATE          = TEMPLATE_DIR + 'footer.rhtml'

	BACKTRACE_EXCLUDE_PATTERN = %r{\.gem|spec/mate|textmate-command|rspec(-(core|expectations|mocks))?/}

	# Figure out which class pending-example-fixed errors are (2.8 change)
	PENDING_FIXED_EXCEPTION = if defined?( RSpec::Core::Pending::PendingExampleFixedError )
		RSpec::Core::Pending::PendingExampleFixedError
	else
		RSpec::Core::PendingExampleFixedError
	end


	### Create a new formatter
	def initialize( output ) # :notnew:
		super
		@previous_nesting_depth = 0
		@example_number = 0
		@failcounter = 0
		@snippet_extractor = RSpec::Core::Formatters::SnippetExtractor.new
		@example_templates = {
			:passed        => self.load_template(PASSED_EXAMPLE_TEMPLATE),
			:failed        => self.load_template(FAILED_EXAMPLE_TEMPLATE),
			:pending       => self.load_template(PENDING_EXAMPLE_TEMPLATE),
			:pending_fixed => self.load_template(PENDFIX_EXAMPLE_TEMPLATE),
		}

		Thread.current['logger-output'] = []
	end


	######
	public
	######

	# Attributes made readable for ERb
	attr_reader :example_group_number, :example_number, :example_count

	# The counter for failed example IDs
	attr_accessor :failcounter


	### Start the page by rendering the header.
	def start( notification )
		@output.puts self.render_header( notification.count )
		@output.flush
	end


	### Callback called by each example group when it's entered --
	def example_group_started( event )
		super
		example_group=event.group
		nesting_depth = event.group.ancestors.length

		# Close the previous example groups if this one isn't a
		# descendent of the previous one
		if @previous_nesting_depth.nonzero? && @previous_nesting_depth >= nesting_depth
			( @previous_nesting_depth - nesting_depth + 1 ).times do
				@output.puts "  </dl>", "</section>", "  </dd>"
			end
		end

		@output.puts "<!-- nesting: %d, previous: %d -->" %
			[ nesting_depth, @previous_nesting_depth ]
		@previous_nesting_depth = nesting_depth

		if @previous_nesting_depth == 1
			@output.puts %{<section class="example-group">}
		else
			@output.puts %{<dd class="nested-group"><section class="example-group">}
		end
		@output.puts %{  <dl>},
			%{  <dt id="%s">%s</dt>} % [
				event.group.name.gsub(/[\W_]+/, '-').downcase,
				h(event.group.description)
			]
		@output.flush
	end
	#alias_method :add_example_group, :example_group_started


	### Fetch any log messages added to the thread-local Array
	def log_messages
		return Thread.current[ 'logger-output' ] || []
	end


	### Callback -- called when the examples are finished.
	def start_dump(notification)
		@previous_nesting_depth.downto( 1 ) do |i|
			@output.puts "  </dl>",
			             "</section>"
			@output.puts "  </dd>" unless i == 1
		end

		@output.flush
	end


	### Callback -- called when an example is entered
	def example_started( notification )
		@example_number += 1
		Thread.current[ 'logger-output' ] ||= []
		Thread.current[ 'logger-output' ].clear
	end


	### Callback -- called when an example is exited with no failures.
	def example_passed( notification )
		status = 'passed'
		example = notification.example
		@output.puts( @example_templates[:passed].result(binding()) )
		@output.flush
	end


	### Callback -- called when an example is exited with a failure.
	def example_failed(failure)
		#super
		example   = failure.example
		counter   = self.failcounter += 1
		exception = failure.exception
    backtrace = failure.formatted_backtrace.map{|line| backtrace_line(line) }.compact
		extra     = self.extra_failure_content( exception )
		template  = if exception.is_a?( PENDING_FIXED_EXCEPTION )
			then @example_templates[:pending_fixed]
			else @example_templates[:failed]
			end
		@output.puts( template.result(binding()) )
		@output.flush
	end


	### Callback -- called when an example is exited via a 'pending'.
	def example_pending( notification )
		status = 'pending'
		example = notification.example
		@output.puts( @example_templates[:pending].result(binding()) )
		@output.flush
	end


	### Return any stuff that should be appended to the current example
	### because it's failed. Returns a snippet of the source around the
	### failure.
	def extra_failure_content( exception )
		return '' unless exception
		backtrace = exception.backtrace.find {|line| line !~ BACKTRACE_EXCLUDE_PATTERN }
		# $stderr.puts "Using backtrace line %p to extract snippet" % [ backtrace ]
		snippet = @snippet_extractor.snippet([ backtrace ])
		return "    <pre class=\"ruby\"><code>#{snippet}</code></pre>"
	end


	### Returns content to be output when a failure occurs during the run; overridden to
	### do nothing, as failures are handled by #example_failed.
	def dump_failures( *unused )
	end


	### Output the content generated at the end of the run.
	# def dump_summary( duration, example_count, failure_count, pending_count )
	# 	@output.puts self.render_footer( duration, example_count, failure_count, pending_count )
	# 	@output.flush
	# end
	
	def dump_summary( summary )
		@output.puts self.render_footer(
          summary.duration,
          summary.example_count,
          summary.failure_count,
          summary.pending_count
        )
		@output.flush
	end

  ### Format backtrace lines to include a textmate link to the file/line in question.
  def backtrace_line( line )
   return nil if line =~ BACKTRACE_EXCLUDE_PATTERN
   return line.strip.gsub( /(?<filename>[^:]*\.rb):(?<line>\d*)/ ) do
     match = $~
     relative_path = match[:filename]
     fullpath = File.expand_path( relative_path )
     line = match[:line]
     base_dir = '/opt/wagn'
       if relative_path =~ /^\.\/tmp\//

       real_path = relative_path.match(/^\.\/tmp\/(\D+)\d+-(.*\.rb)/)
       core_search_path = "#{base_dir}/**/#{real_path[1]}#{real_path[2]}"
       deck_search_path = "**/#{real_path[1]}#{real_path[2]}"
#       results = Dir.glob(core_search_path).flatten
       
       #results.flatten!
       if (results = Dir.glob(core_search_path).flatten and results.size == 1) 
         fullpath = results.first
         relative_path = fullpath
         line = line.to_i - 5
       elsif (results = Dir.glob(deck_search_path).flatten and results.size == 1)
         fullpath = fullpath.sub(/tmp\/.*/,results.first)#results.first
         relative_path = results.first
         line = line.to_i - 5
       end
     end
     if relative_path.include? 'spec'
       relative_path = 'spec: ' + File.basename(relative_path)
     else
       relative_path = relative_path.sub("#{base_dir}/",'').sub('mod/','mod: ')
     end
     %|<a href="txmt://open?url=file://%s&amp;line=%s">%s:%s</a>| %
       [ fullpath, line, relative_path, line ]
    end
  end

	### Render the header template in the context of the receiver.
	def render_header( example_count )
		template = self.load_template( HEADER_TEMPLATE )
		return template.result( binding() )
	end


	### Render the footer template in the context of the receiver.
	def render_footer( duration, example_count, failure_count, pending_count )
		template = self.load_template( FOOTER_TEMPLATE )
		return template.result( binding() )
	end


	### Load the ERB template at +templatepath+ and return it.
	def load_template( templatepath )
		return ERB.new( templatepath.read, nil, '%<>' ).freeze
	end
end # class RSpec::Core::Formatter::WebKitFormatter
