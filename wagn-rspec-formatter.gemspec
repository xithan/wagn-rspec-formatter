# -*- encoding: utf-8 -*-
# stub: wagn-rspec-formatter 0.borked.pre.20140914094308 ruby lib

Gem::Specification.new do |s|
  s.name = "wagn-rspec-formatter"
  s.version = "2.4.0"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger","Philipp Kuehl"]
  s.date = "2014-09-14"
  s.description   = "a webkit-aware pretty formatter for RSpec with a few adaptions for Wagn developers"
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "History.rdoc", "README.rdoc"]
  s.files = ["History.rdoc", "LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "data/wagn-rspec-formatter/css/textmate-rspec.css", "data/wagn-rspec-formatter/images/clock.png", "data/wagn-rspec-formatter/images/cross_circle.png", "data/wagn-rspec-formatter/images/cross_circle_frame.png", "data/wagn-rspec-formatter/images/cross_octagon.png", "data/wagn-rspec-formatter/images/cross_octagon_frame.png", "data/wagn-rspec-formatter/images/cross_shield.png", "data/wagn-rspec-formatter/images/exclamation.png", "data/wagn-rspec-formatter/images/exclamation_frame.png", "data/wagn-rspec-formatter/images/exclamation_shield.png", "data/wagn-rspec-formatter/images/exclamation_small.png", "data/wagn-rspec-formatter/images/plus_circle.png", "data/wagn-rspec-formatter/images/plus_circle_frame.png", "data/wagn-rspec-formatter/images/question.png", "data/wagn-rspec-formatter/images/question_frame.png", "data/wagn-rspec-formatter/images/question_shield.png", "data/wagn-rspec-formatter/images/question_small.png", "data/wagn-rspec-formatter/images/tick.png", "data/wagn-rspec-formatter/images/tick_circle.png", "data/wagn-rspec-formatter/images/tick_circle_frame.png", "data/wagn-rspec-formatter/images/tick_shield.png", "data/wagn-rspec-formatter/images/tick_small.png", "data/wagn-rspec-formatter/images/tick_small_circle.png", "data/wagn-rspec-formatter/images/ticket.png", "data/wagn-rspec-formatter/images/ticket_arrow.png", "data/wagn-rspec-formatter/images/ticket_exclamation.png", "data/wagn-rspec-formatter/images/ticket_minus.png", "data/wagn-rspec-formatter/images/ticket_pencil.png", "data/wagn-rspec-formatter/images/ticket_plus.png", "data/wagn-rspec-formatter/images/ticket_small.png", "data/wagn-rspec-formatter/js/jquery-2.1.0.min.js", "data/wagn-rspec-formatter/js/textmate-rspec.js", "data/wagn-rspec-formatter/templates/failed.rhtml", "data/wagn-rspec-formatter/templates/footer.rhtml", "data/wagn-rspec-formatter/templates/header.rhtml", "data/wagn-rspec-formatter/templates/page.rhtml", "data/wagn-rspec-formatter/templates/passed.rhtml", "data/wagn-rspec-formatter/templates/pending-fixed.rhtml", "data/wagn-rspec-formatter/templates/pending.rhtml", "docs/tmrspec-example.png", "docs/tmrspecopts-shellvar.png", "lib/rspec/core/formatters/bagn.rb"]
  s.homepage = "http://github.com/xithan/rspec-wagn-formatter"
  s.licenses = ["Ruby"]
  s.post_install_message = "\n\nYou can use this formatter from TextMate by setting the TM_RSPEC_OPTS \nshell variable (in the 'Advanced' preference pane) to:\n\n    --format RSpec::Core::Formatters::Wagn\n\nHave fun!\n\n"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.2.2"
  s.summary = "a webkit-aware pretty formatter for RSpec"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec-core>, ["~> 2.14"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_development_dependency(%q<hoe>, ["~> 3.12"])
    else
      s.add_dependency(%q<rspec-core>, ["~> 2.14"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_dependency(%q<hoe>, ["~> 3.12"])
    end
  else
    s.add_dependency(%q<rspec-core>, ["~> 2.14"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
    s.add_dependency(%q<hoe>, ["~> 3.12"])
  end
end
