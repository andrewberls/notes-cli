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
      default_tasks = Notes::Tasks.defaults
      @stats = Notes::Stats.compute(default_tasks)

      @tasks = default_tasks.tap do |tasks|
        tasks.each { |filename, ts| tasks[filename] = ts.map(&:to_json) }
      end

      { stats: @stats, all_tasks: @tasks }.to_json
    end

  end
end
