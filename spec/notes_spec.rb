require File.dirname(__FILE__) + '/spec_helper'

describe 'Notes' do

  context 'shortname' do
    specify do
      Dir.should_receive(:pwd).and_return('/path/to/notes-cli')
      Notes.shortname('/path/to/notes-cli/bin/notes').should == 'bin/notes'
    end
  end

end
