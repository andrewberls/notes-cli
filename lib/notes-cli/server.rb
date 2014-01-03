require 'rack'
require 'optparse'
require 'notes-cli/web'

module Notes
  class Server
    SERVER_DEFAULTS = {
      :Host => '127.0.0.1',
      :Port => '9292'
    }

    def initialize(argv)
      @options = SERVER_DEFAULTS.merge(parse_options(argv))
    end

    def parse_options(args)
      options = {}
      OptionParser.new do |opts|
        opts.on('-p', '--port [PORT]', 'The port to run on') do |port|
          options[:Port] = port
        end
      end.parse!(args)

      options
    end

    def start
      Rack::Handler::WEBrick.run(Notes::Web, @options) do |server|
          [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
      end
    end

  end
end
