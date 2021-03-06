require 'sinatra'
require 'json'

# A web dashboard for annotations
# This is intended to be mounted within an application, e.g.
#
#   mount Notes::Web => '/notes'
#
module Notes
  class Web < Sinatra::Base

    set :root, File.expand_path(File.dirname(__FILE__) + "/../../web")
    set :public_folder, Proc.new { "#{root}/assets" }
    set :views, Proc.new { "#{root}/views" }

    get '/' do
      # TODO: there has to be a better way to get the mounted root
      @root = request.env["SCRIPT_NAME"]

      erb :index
    end

    get '/tasks.json' do
      # TODO: cache this somehow
      options = Notes::Options.defaults

      if flags = params[:flags]
        options[:flags] = flags
      end

      tasks  = Notes::Tasks.all(options)
      @stats = Notes::Stats.compute(tasks)
      @tasks = tasks.map(&:to_json)

      { stats: @stats, tasks: @tasks }.to_json
    end

  end
end
