require File.dirname(__FILE__) + '/spec_helper'
require 'tempfile'

describe 'stats' do
  context 'compute' do
    let(:file)    { Tempfile.new('example') }
    let(:options) { Notes::Options.defaults }
    let(:tasks)   { Notes::Tasks.for_file(file.path, options[:flags]) }

    before do
      File.open(file, 'w') do |f|
        f.write "TODO: one\n"
        f.write "two\n"
        f.write "TODO: three\n"
        f.write "OPTIMIZE: four\n"
        f.write "five\n"
        f.write "six\n"
        f.write "seven FIXME\n"
      end
    end

    it 'counts stats correctly' do
      Notes::Stats.flag_counts(tasks).should == {
        'TODO' => 2,
        'OPTIMIZE' => 1,
        'FIXME'  => 1
      }
    end

    it 'aggregates found flags' do
      Notes::Stats.found_flags(tasks).should == ['TODO', 'OPTIMIZE', 'FIXME']
    end
  end
end
