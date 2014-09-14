require 'stringio'
require 'cgi'
require 'shellwords'

module RSpec
  module Mate
    class Runner
      def run_files(stdout, options={})
        files = ENV['TM_SELECTED_FILES'] ? Shellwords.shellwords(ENV['TM_SELECTED_FILES']) : ["spec/"]
        options.merge!({:files => files})
        run(stdout, options)
      end


      def run_all(stdout, options={})
        run(stdout, options)
      end
      
      def run_file(stdout, options={})
        options.merge!({:files => [single_file]})
        run(stdout, options)
      end

      def run_last_remembered_file(stdout, options={})
        options.merge!({:files => [last_remembered_single_file]})
        run(stdout, options)
      end
      
      def debug_last_remembered_file(stdout, options={})
        options.merge!({:files => [last_remembered_single_file],
                        :formatter=> 'documentation',
                        :rescue=> 'true'})
        
        iterm_command= wagn_command(options).gsub!('\\\\','\\\\\\\\\\\\\\\\')
        #system %(osascript -e 'tell application "iTerm"' -e 'make new terminal' -e 'tell the first terminal' -e 'activate current session' -e 'launch session "Default Session"' -e 'tell the last session' -e 'write text "cd #{project_directory}"' -e 'write text "#{iterm_command}"' -e 'end tell' -e 'end tell' -e 'end tell')
        system %(osascript -e 'tell application "iTerm"' -e 'make new terminal' -e 'tell the first terminal' -e 'activate current session' -e 'tell the last session' -e 'write text "cd #{project_directory}"' -e 'write text "#{iterm_command}"' -e 'end tell' -e 'end tell' -e 'end tell')
      end

      def run_focussed(stdout, options={})
        options.merge!(
          {
            :files => [single_file],
            :line  => ENV['TM_LINE_NUMBER']
          }
        )
        run(stdout, options)
      end
      
      def run_smart(stdout, options={})
        if single_file.include? "_spec"
          save_as_last_remembered_file(single_file,ENV['TM_LINE_NUMBER'])
          run_focussed(stdout, options)
        else
          save_as_last_remembered_file(single_file)
          options.merge!({:files => [single_file]})
          run(stdout, options)
        end
      end
      
      def wagn_files_arg? files  # files argument for wagn rspec and not for rspec
         files and (wagn_rspec? or deck_rspec?) and (!files.first.include? "_spec" or !File.exists?(files.first))
      end
      
      def rspec_args options={}
        argv = []
        default_formatter = rspec3? ? 'RSpec::Mate::Formatters::TextMateFormatter' : 'textmate'
        formatter  = options[:formatter] || ENV['TM_RSPEC_FORMATTER'] || default_formatter
        
        argv << '--format' << formatter
        #argv << '-r' << File.join(File.dirname(__FILE__), 'text_mate_formatter') if formatter == 'RSpec::Mate::Formatters::TextMateFormatter'
        argv << '-r' << "#{File.join(File.dirname(__FILE__), 'filter_bundle_backtrace')}".gsub(' ','\\\\\\\\ ') #if formatter != 'documentation'

        if ENV['TM_RSPEC_OPTS']
          argv += ENV['TM_RSPEC_OPTS'].split(" ")
        end
        
        if wagn_rspec? and ENV['TM_WAGN_PATH']
          argv << '--default-path' <<  ENV['TM_WAGN_PATH'] || '/opt/wagn'
        elsif deck_rspec?
          argv << '--default-path' <<  'mod'
        end
        if not wagn_files_arg? options[:files]
          argv += files_args( options[:files], options[:line] )
        end
        argv
      end
      
      def files_args files, line
        return [] unless files
        if rspec3?
          # If :line is given, only the first file from :files is used. This should be ok though, because
          # :line is only ever set in #run_focussed, and there :files is always set to a single file only.
          argv = line ? ["#{files.first}:#{line}"] : files.dup
        else
          argv = files.dup
          if line
            argv << '--line'
            argv << line
          end
        end
      end
      
      def wagn_args options={}
        argv = []
        argv << '--rescue' if options[:rescue]
        argv << (options[:coverage] ? '--simplecov' : '--no-simplecov')
        if wagn_files_arg? options[:files]
          if wagn_rspec?
            argv << '--core-spec'
          else dec_rspec?
            argv << '--spec'
          end
          argv += files_args( options[:files], options[:line] )
        end
        argv
      end
      
      def args_str options={}
        wagn_args(options).join(' ') + ' -- ' + rspec_args(options).join(' ')
      end
      
      def wagn_command options
        "bundle exec wagn rspec #{args_str(options)}"
      end
      
      def run(stdout, options)
        stderr     = StringIO.new
        old_stderr = $stderr
        $stderr    = stderr
        
        Dir.chdir(project_directory) do
          if wagn_rspec? or deck_rspec?
            system wagn_command(options)
          elsif use_binstub?
            system 'bin/rspec', *command_args(options)
          else
            ::RSpec::Core::Runner.disable_autorun!
            ::RSpec::Core::Runner.run(command_args(options), stderr, stdout)
          end
        end
      rescue Exception => e
        require 'pp'

        stdout <<
          "<h1>Uncaught Exception</h1>" <<
          "<p>#{e.class}: #{e.message}</p>" <<
          "<pre>" <<
            CGI.escapeHTML(e.backtrace.join("\n  ")) <<
          "</pre>" <<
          "<h2>Options:</h2>" <<
          "<pre>" <<
            CGI.escapeHTML(PP.pp(options, '')) <<
          "</pre>"
      ensure
        unless stderr.string == ""
          stdout <<
            "<h2>stderr:</h2>" <<
            "<pre>" <<
              CGI.escapeHTML(stderr.string) <<
            "</pre>"
        end

        $stderr = old_stderr
      end

      def save_as_last_remembered_file(file,line=nil)
        if line and file.include? '_spec'
          file += ":#{line}"    
        end
        File.open(last_remembered_file_cache, "w") do |f|
          f << file
        end
      end

      def last_remembered_file_cache
        "/tmp/textmate_rspec_last_remembered_file_cache.txt"
      end


    private
      
      def last_remembered_single_file
        file = File.read(last_remembered_file_cache).strip

        if file.size > 0
          File.expand_path(file)
        end
      end

      def project_directory
        if wagn_rspec? and ENV['TM_WAGN_CORE_TESTDECK']
          ENV['TM_WAGN_CORE_TESTDECK']
        elsif deck_rspec? and ENV['TM_WAGN_DECK']
          ENV['TM_WAGN_DECK']
        else
          File.expand_path(ENV['TM_PROJECT_DIRECTORY']) rescue File.dirname(single_file)
        end
      end

      def single_file
        File.expand_path(ENV['TM_FILEPATH'])
      end
    end
  end
end
