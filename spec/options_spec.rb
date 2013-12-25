require File.dirname(__FILE__) + '/spec_helper'

describe 'arg groups' do
  context 'with no options' do
    it "accepts a list of files" do
      Notes::Options.arg_groups(['one.rb', 'two.rb']).should == [['one.rb', 'two.rb']]
    end

    it "accepts a directory" do
      Notes::Options.arg_groups(['app/']).should == [['app/']]
    end

    it "looks in the current directory if none provided" do
      Notes::Options.arg_groups(['-f', 'src/']).should == [[Dir.pwd], ['-f', 'src/']]
    end
  end

  context 'with options' do
    it "accepts a list of files" do
      ['-f', '--flags'].each do |flag|
        Notes::Options.arg_groups(['one.rb', 'two.rb', flag, 'broken']).should == [['one.rb', 'two.rb'], [flag, 'broken']]
      end
    end

    it "accepts a directory" do
      ['-e', '--exclude'].each do |flag|
        Notes::Options.arg_groups(['app/', flag, 'log/']).should == [['app/'], [flag, 'log/']]
      end
    end

    it "groups flags correctly" do
      Notes::Options.arg_groups(['app/', '-f', 'broken', '-e', 'log/']).should == [['app/'], ['-f', 'broken'], ['-e', 'log/']]
      Notes::Options.arg_groups(['one.rb', 'two.rb', '-e', 'tmp', '-f', 'findme']).should == [['one.rb', 'two.rb'], ['-e', 'tmp'], ['-f', 'findme']]
    end

    it "accepts mixed length flags" do
      expected = [['one.rb', 'two.rb'], ['--exclude', 'tmp'], ['-f', 'findme']]
      Notes::Options.arg_groups(['one.rb', 'two.rb', '--exclude', 'tmp', '-f', 'findme']).should == expected
    end

    it "handles multiple flag arguments" do
      expected = [['src/'], ['-f', 'broken', 'findme'], ['-e', 'log/', 'tmp/']]
      Notes::Options.arg_groups(['src/', '-f', 'broken', 'findme', '-e', 'log/', 'tmp/']).should == expected
    end
  end
end


describe "opt parsing" do
  context 'with no options' do
    it "accepts a list of files" do
      files = ['one.rb', 'two.rb']
      opts = Notes::Options.parse(files)
      opts[:locations].should == files
    end

    it "accepts a directory" do
      opts = Notes::Options.parse(['app/'])
      opts[:locations].should == ['app/']
    end

    it "looks in the current directory if none provided" do
      opts = Notes::Options.parse(['-f', 'src/'])
      opts[:flags].should include('src')
    end
  end

  context 'with options' do
    it "accepts a list of files" do
      ['-f', '--flags'].each do |flag|
        opts = Notes::Options.parse(['one.rb', 'two.rb', flag, 'broken'])
        opts[:locations].should == ['one.rb', 'two.rb']
        opts[:flags].should include('broken')
      end
    end

    it "accepts a directory" do
      ['-e', '--exclude'].each do |flag|
        opts = Notes::Options.parse(['app/', flag, 'log/'])
        opts[:exclude].should include('log')
      end
    end

    it "groups flags correctly" do
      opts = Notes::Options.parse(['app/', '-f', 'broken', '-e', 'log/'])
      opts[:flags].should include('broken')
      opts[:exclude].should include('log')

      opts = Notes::Options.parse(['one.rb', 'two.rb', '-e', 'tmp', '-f', 'findme'])
      opts[:flags].should include('findme')
      opts[:exclude].should include('tmp')
    end

    it "accepts mixed length flags" do
      opts = Notes::Options.parse(['one.rb', 'two.rb', '--exclude', 'tmp', '-f', 'findme'])
      opts[:flags].should include('findme')
      opts[:exclude].should include('tmp')
    end

    it "handles multiple flag arguments" do
      opts = Notes::Options.parse(['src/', '-f', 'broken', 'findme', '-e', 'log/', 'tmp/'])
      opts[:flags].should include('broken', 'findme')
      opts[:exclude].should include('log', 'tmp')
    end
  end
end

describe 'defaults' do
  context 'when Rails is not defined' do
    specify { defined?(Rails).should be_nil }

    it 'does not exclude anything by default' do
      Notes::Options.default_excludes.should == []
    end

    it 'uses the current directory by default' do
      Notes.root.should == Dir.pwd
    end
  end

  context 'when Rails is defined' do
    before { Object.const_set('Rails', Module.new) }
    after  { Object.send(:remove_const, :Rails) }

    specify { defined?(Rails).should_not be_nil }

    it 'excludes slow directories by default' do
      Notes::Options.default_excludes.should == %w(tmp log)
    end

    it 'uses the Rails root by default' do
      Rails.should_receive(:root).and_return 'root'
      Notes.root.should == 'root'
    end
  end
end
