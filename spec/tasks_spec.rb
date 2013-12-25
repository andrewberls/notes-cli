require File.dirname(__FILE__) + '/spec_helper'
require 'tempfile'

describe 'tasks' do

  context 'matching_flags' do
    specify do
      Notes::Tasks.matching_flags("TODO: foo", ["TODO"]).should == ["TODO"]
    end

    specify do
      Notes::Tasks.matching_flags("TODO: bar", ["FIXME"]).should == []
    end

    specify do
      Notes::Tasks.matching_flags("fixme", ["FIXME", "foo"]).should == ["FIXME"]
    end

    specify do
      Notes::Tasks.matching_flags("TODO: foo FIXME", ["TODO","FIXME", "OPTIMIZE"])
        .should == ["TODO","FIXME"]
    end
  end

  context 'for_file' do
    let(:file)    { Tempfile.new('example') }
    let(:options) { Notes::Options.defaults }
    let(:tasks)   { Notes::Tasks.for_file(file.path, options[:flags]) }

    before do
      File.open(file, 'w') do |f|
        f.write "TODO: one\n"
        f.write "two\n"
        f.write "three\n"
        f.write "findme: four\n"
        f.write "five\n"
        f.write "six\n"
        f.write "seven FIXME\n"
      end
    end

    specify { tasks.length.should == 2 }

    it 'counts custom flags correctly' do
      tasks = Notes::Tasks.for_file(file.path, options[:flags] + ["FINDME"])
      tasks.length.should == 3
    end

    it 'parses lines correctly' do
      tasks = Notes::Tasks.for_file(file.path, options[:flags] + ["FINDME"])
      t0, t1, t2 = tasks

      t0.line_num.should == 1
      t0.line.should == "TODO: one"
      t0.flags.should == ["TODO"]
      t0.context.should == "two\nthree\nfindme: four\nfive\nsix"

      t1.line_num.should == 4
      t1.line.should == "findme: four"
      t1.flags.should == ["FINDME"]
      t1.context.should == "five\nsix\nseven FIXME"

      t2.line_num.should == 7
      t2.line.should == "seven FIXME"
      t2.flags.should == ["FIXME"]
      t2.context.should == ""
    end

    # This is kind of annoying - we have a perfectly valid file to parse,
    # but it's not in a git repo. We could build an abstraction layer over
    # the git call, but that doesn't seem worth it, so hand-wave the git parts
    # and test simple field parsing
    #
    # Also directly testing private methods, somebody call the TDD police
    it 'reads information from git' do
      Notes.should_receive(:blame).and_return({
        "author" => "Andrew Berls",
        "author-time" => "1381862180"
      })

      info = Notes::Tasks.send(:line_info, 'doesnt_matter_stubbed_out', 0)
      info[:author].should == "Andrew Berls"
      info[:date].should == '2013-10-15 11:36:20 -0700'
    end
  end

end

