require 'spec_helper'

module RSpec
  module Mate
    describe SwitchCommand do
      class << self
        def expect_twins(pair)
          specify do
            pair[0].should twin(pair[1])
          end
        end
      end

      RSpec::Matchers.define :twin do |*args|
        expected = args.shift
        opts     = args.last || {:webapp => false}

        File.stub!(:exist?).and_return(opts[:webapp])

        match do |actual|
          command = SwitchCommand.new
          command.twin(actual) == expected && command.twin(expected) == actual
        end
      end

      RSpec::Matchers.define :be_a do |expected|
        match do |actual|
          SwitchCommand.new.file_type(actual) == expected
        end
      end

      describe "in a regular app" do
        expect_twins [
          "/Users/aslakhellesoy/scm/rspec/trunk/RSpec.tmbundle/Support/spec/rspec/mate/switch_command_spec.rb",
          "/Users/aslakhellesoy/scm/rspec/trunk/RSpec.tmbundle/Support/lib/rspec/mate/switch_command.rb"
        ]

        it "suggest a plain spec" do
          "/a/full/path/spec/snoopy/mooky_spec.rb".should be_a("spec")
        end

        it "suggests a plain file" do
          "/a/full/path/lib/snoopy/mooky.rb".should be_a("file")
        end

        it "create a spec for spec files" do
          regular_spec = <<-SPEC
require 'spec_helper'

describe ${1:${TM_FILENAME/(?:\\A|_)([A-Za-z0-9]+)(?:(?:_spec)?\\.[a-z]+)*/(?2::\\u$1)/g}} do
  $0
end
SPEC
          SwitchCommand.new.content_for('spec', "spec/foo/zap_spec.rb").should == regular_spec
          SwitchCommand.new.content_for('spec', "spec/controller/zap_spec.rb").should == regular_spec
        end

        it "create class for regular file" do
          file = <<-EOF
module Foo
  class Zap
  end
end
EOF
          SwitchCommand.new.content_for('file', "lib/foo/zap.rb").should == file
          SwitchCommand.new.content_for('file', "some/other/path/lib/foo/zap.rb").should == file
        end
      end

      describe "in a Rails or Merb app" do
        def twin(expected)
          super(expected, :webapp => true)
        end

        expect_twins [
          "/a/full/path/app/controllers/mooky_controller.rb",
          "/a/full/path/spec/controllers/mooky_controller_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/controllers/application_controller.rb",
          "/a/full/path/spec/controllers/application_controller_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/controllers/job_applications_controller.rb",
          "/a/full/path/spec/controllers/job_applications_controller_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/helpers/application_helper.rb",
          "/a/full/path/spec/helpers/application_helper_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/models/mooky.rb",
          "/a/full/path/spec/models/mooky_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/helpers/mooky_helper.rb",
          "/a/full/path/spec/helpers/mooky_helper_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/views/mooky/show.html.erb",
          "/a/full/path/spec/views/mooky/show.html.erb_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/views/mooky/show.html.haml",
          "/a/full/path/spec/views/mooky/show.html.haml_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/views/mooky/show.html.slim",
          "/a/full/path/spec/views/mooky/show.html.slim_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/views/mooky/show.rhtml",
          "/a/full/path/spec/views/mooky/show.rhtml_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/views/mooky/show.js.rjs",
          "/a/full/path/spec/views/mooky/show.js.rjs_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/views/mooky/show.rjs",
          "/a/full/path/spec/views/mooky/show.rjs_spec.rb"
        ]

        expect_twins [
          "/a/full/path/lib/foo/mooky.rb",
          "/a/full/path/spec/lib/foo/mooky_spec.rb"
        ]

        expect_twins [
          "/a/full/path/app/lib/foo/mooky.rb",
          "/a/full/path/spec/app/lib/foo/mooky_spec.rb"
        ]

        it "suggests a controller spec" do
          "/a/full/path/spec/controllers/mooky_controller_spec.rb".should be_a("controller spec")
        end

        it "suggests a model spec" do
          "/a/full/path/spec/models/mooky_spec.rb".should be_a("model spec")
        end

        it "suggests a helper spec" do
          "/a/full/path/spec/helpers/mooky_helper_spec.rb".should be_a("helper spec")
        end

        it "suggests a view spec for erb" do
          "/a/full/path/spec/views/mooky/show.html.erb_spec.rb".should be_a("view spec")
        end

        it "suggests a view spec for haml" do
          "/a/full/path/spec/views/mooky/show.html.haml_spec.rb".should be_a("view spec")
        end

        it "suggests a view spec for slim" do
          "/a/full/path/spec/views/mooky/show.html.slim_spec.rb".should be_a("view spec")
        end

        it "suggests an rjs view spec" do
          "/a/full/path/spec/views/mooky/show.js.rjs_spec.rb".should be_a("view spec")
        end

        it "suggests a controller" do
          "/a/full/path/app/controllers/mooky_controller.rb".should be_a("controller")
        end

        it "suggests a model" do
          "/a/full/path/app/models/mooky.rb".should be_a("model")
        end

        it "suggests a helper" do
          "/a/full/path/app/helpers/mooky_helper.rb".should be_a("helper")
        end

        it "suggests a view" do
          "/a/full/path/app/views/mooky/show.html.erb".should be_a("view")
        end

        it "suggests an rjs view" do
          "/a/full/path/app/views/mooky/show.js.rjs".should be_a("view")
        end

        it "create a spec that requires a helper" do
          SwitchCommand.new.content_for('controller spec', "spec/controllers/mooky_controller_spec.rb").split("\n")[0].should ==
            "require 'spec_helper'"
        end

        it "creates a controller if twinned from a controller spec" do
          SwitchCommand.new.content_for('controller', "spec/controllers/mooky_controller.rb").should == <<-EXPECTED
class MookyController < ApplicationController
end
EXPECTED
        end

        it "creates a model if twinned from a model spec" do
          SwitchCommand.new.content_for('model', "spec/models/mooky.rb").should == <<-EXPECTED
class Mooky < ActiveRecord::Base
end
EXPECTED
        end

        it "creates a helper if twinned from a helper spec" do
          SwitchCommand.new.content_for('helper', "spec/helpers/mooky_helper.rb").should == <<-EXPECTED
module MookyHelper
end
EXPECTED
        end

        it "creates an empty view if twinned from a view spec" do
          SwitchCommand.new.content_for('view', "spec/views/mookies/index.html.erb_spec.rb").should == ""
        end
      end

      describe '#described_class_for' do
        base = '/Users/foo/Code/bar'
        {
          # normal project
          '/Users/foo/Code/bar/lib/some_name.rb' => 'SomeName',
          '/Users/foo/Code/bar/lib/some/long_file_name.rb' => 'Some::LongFileName',
          '/Users/foo/Code/bar/lib/my/own/file.rb' => 'My::Own::File',

          # rails
          '/Users/foo/Code/bar/app/controllers/file_controller.rb' => 'FileController',
          '/Users/foo/Code/bar/app/models/my/own/file.rb' => 'My::Own::File',
          '/Users/foo/Code/bar/app/other/my/own/file.rb' => 'My::Own::File',
        }.each_pair do |path, class_name|
          it "extracts the full class name from the path (#{class_name})" do
            expect(subject.described_class_for(path, base)).to eq(class_name)
          end
        end
      end
    end
  end
end
