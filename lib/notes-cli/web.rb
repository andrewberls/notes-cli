require 'sinatra'
require 'json'

module Notes
  class Web < Sinatra::Base

    set :root, File.expand_path(File.dirname(__FILE__) + "/../../web")
    set :public_folder, Proc.new { "#{root}/assets" }
    set :views, Proc.new { "#{root}/views" }

    # This is intended to be mounted within an application, e.g.
    # mount Notes::Web => '/notes'
    get '/' do
      # TODO: there has to be a better way to get the mounted root
      @root = request.env["SCRIPT_NAME"]

      @tasks = Notes::Tasks.defaults
      erb :index
    end

    get '/tasks.json' do
      tasks = Notes::Tasks.defaults
      tasks.each { |filename, ts| tasks[filename] = ts.map(&:to_json) }
      tasks.to_json
    end

  end
end
