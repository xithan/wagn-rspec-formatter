require "fileutils"

module RSpec
  module Mate
    # This is based on Ruy Asan's initial code:
    # http://ruy.ca/posts/6-A-simple-switch-between-source-and-spec-file-command-for-textmate-with-auto-creation-
    class SwitchCommand
      def go_to_twin(project_directory, filepath)
        #otoer = twin(filepath)
        other = wagn_twin(project_directory, filepath)

        if File.file?(other)
          %x{ "$TM_SUPPORT_PATH/bin/mate" "#{other}" }
        else
          relative  = other[project_directory.length+1..-1]
          file_type = file_type(other)

          if create?(relative, file_type)
            content = content_for(file_type, relative)
            write_and_open(other, content)
          end
        end
      end

      module Framework
        def merb?
          File.exist?(File.join(self, 'config', 'init.rb'))
        end

        def merb_or_rails?
          merb? || rails?
        end

        def rails?
          File.exist?(File.join(self, 'config', 'boot.rb'))
        end
      end

      def wagn_twin(project_directory, path)
        if path.include? 'spec'
          file = File.basename(path,"_spec.rb")
          Dir.glob("#{project_directory}/**/#{file}.rb").first
        else
          file = File.basename(path,".rb")
          Dir.glob("#{project_directory}/**/#{file}_spec.rb").first
        end
        
      end

      def twin(path)
        if path =~ /^(.*?)\/(lib|app|spec)\/(.*?)$/
          framework, parent, rest = $1, $2, $3
          framework.extend Framework

          case parent
            when 'lib', 'app' then
              if framework.merb_or_rails?
                if path.include?("/app/lib/")
                  path = path.gsub("/app/lib/", "/spec/app/lib/")
                else
                  path = path.gsub(/\/app\//, "/spec/")
                  path = path.gsub(/\/lib\//, "/spec/lib/")
                end
              else
                path = path.gsub(/\/lib\//, "/spec/")
              end

              path = path.gsub(/\.rb$/, "_spec.rb")
              path = path.gsub(/\.erb$/, ".erb_spec.rb")
              path = path.gsub(/\.haml$/, ".haml_spec.rb")
              path = path.gsub(/\.slim$/, ".slim_spec.rb")
              path = path.gsub(/\.rhtml$/, ".rhtml_spec.rb")
              path = path.gsub(/\.rjs$/, ".rjs_spec.rb")
            when 'spec' then
              path = path.gsub(/\.rjs_spec\.rb$/, ".rjs")
              path = path.gsub(/\.rhtml_spec\.rb$/, ".rhtml")
              path = path.gsub(/\.erb_spec\.rb$/, ".erb")
              path = path.gsub(/\.haml_spec\.rb$/, ".haml")
              path = path.gsub(/\.slim_spec\.rb$/, ".slim")
              path = path.gsub(/_spec\.rb$/, ".rb")

              if framework.merb_or_rails?
                if path.include?("/spec/app/lib/")
                  path = path.gsub("/spec/app/lib/", "/app/lib/")
                else
                  path = path.gsub(/\/spec\/lib\//, "/lib/")
                  path = path.gsub(/\/spec\//, "/app/")
                end
              else
                path = path.gsub(/\/spec\//, "/lib/")
              end
          end

          return path
        end
      end

      def file_type(path)
        if path =~ /^(.*?)\/(spec)\/(controllers|helpers|models|views)\/(.*?)$/
          return "#{$3[0..-2]} spec"
        end

        if path =~ /^(.*?)\/(app)\/(controllers|helpers|models|views)\/(.*?)$/
          return $3[0..-2]
        end

        if path =~ /_spec\.rb$/
          return "spec"
        end

        "file"
      end

      def create?(relative_twin, file_type)
        answer = `'#{ ENV['TM_SUPPORT_PATH'] }/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog' yesno-msgbox --no-cancel --icon document --informative-text "#{relative_twin}" --text "Create missing #{file_type}?"`
        answer.to_s.chomp == "1"
      end

      def content_for(file_type, relative_path)
        case file_type
          when /spec$/ then
            spec(relative_path)
          when "controller"
            <<-CONTROLLER
class #{class_from_path(relative_path)} < ApplicationController
end
CONTROLLER
          when "model"
            <<-MODEL
class #{class_from_path(relative_path)} < ActiveRecord::Base
end
MODEL
          when "helper"
            <<-HELPER
module #{class_from_path(relative_path)}
end
HELPER
          when "view"
            ""
          else
            klass(relative_path)
        end
      end

      def class_from_path(path)
        underscored = path.split('/').last.split('.rb').first
        parts = underscored.split('_')

        parts.inject("") do |word, part|
          word << part.capitalize
          word
        end
      end

      # Extracts the snippet text
      def snippet(snippet_name)
        snippet_file = File.expand_path(
          File.dirname(__FILE__) +
          "/../../../../Snippets/#{snippet_name}"
        )

        xml = File.open(snippet_file).read

        xml.match(/<key>content<\/key>\s*<string>([^<]*)<\/string>/m)[1]
      end

      def spec(path)
        content = <<-SPEC
require 'spec_helper'

#{snippet("Describe_type.tmSnippet")}
SPEC
      end

      def klass(relative_path, content=nil)
        parts     = relative_path.split('/')
        lib_index = parts.index('lib') || 0
        parts     = parts[lib_index+1..-1]
        lines     = Array.new(parts.length*2)

        parts.each_with_index do |part, n|
          part   = part.capitalize
          indent = "  " * n

          line = if part =~ /(.*)\.rb/
            part = $1
            "#{indent}class #{part}"
          else
            "#{indent}module #{part}"
          end

          lines[n] = line
          lines[lines.length - (n + 1)] = "#{indent}end"
        end

        lines.join("\n") + "\n"
      end

      def write_and_open(path, content)
        FileUtils.mkdir_p(File.dirname(path))
        described = described_class_for(path, ENV['TM_PROJECT_DIRECTORY'])
        File.open(path, 'w') do |f|
          f.puts "require 'spec_helper'"
          f.puts ''
          f.puts "describe #{described} do"
          f.puts '  ' # <= caret will be here
          f.puts 'end'
        end
        system ENV['TM_SUPPORT_PATH']+'/bin/mate', path, '-l4:3'
      end

      def described_class_for(path, base_path)
        relative_path = path[base_path.size..-1]
        camelize = lambda {|part| part.gsub(/_([a-z])/){$1.upcase}.gsub(/^([a-z])/){$1.upcase}}
        parts = File.dirname(relative_path).split('/').compact.reject(&:empty?)
        parts.shift if parts.first == 'app'
        described = Array(parts[1..-1]).map(&camelize)
        described << camelize.call(File.basename(path, '_spec.rb').split('.').first)
        described = described.compact.reject(&:empty?).join('::')
        described
      end
    end

  end
end
