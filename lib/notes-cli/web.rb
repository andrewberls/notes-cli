require 'sinatra'

module Notes
  class Web < Sinatra::Base

    set :root, File.expand_path(File.dirname(__FILE__) + "/../../web")
    set :public_folder, Proc.new { "#{root}/assets" }
    set :views, Proc.new { "#{root}/views" }

    get '/notes' do
      @options = Notes::Options.parse({})
      @files   = Notes.valid_files(@options)
      @tasks   = Notes::Tasks.for_files(@files, @options[:flags])

      erb :index
    end

  end
end
