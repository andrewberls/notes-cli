## Notes - A tool for managing source code annotations

Notes is a tool for tracking source code annotations such as TODO or FIXME. A command-line interface searches files
in a directory and prints annotations, while a web interface provides visualization and filtering tools.


Default annotations searched for are: __TODO__, __FIXME__, and __OPTIMIZE__. Custom annotations or directories to ignore (such as log directories) can be specified with command-line arguments, detailed further.


### INSTALLATION:
`gem install notes-cli`

This will install the `notes` executable on your system.

## Using the web interface

Notes ships with a web interface for displaying and filtering annotations. It can be run as a standalone server, 
or mounted as a Rack endpoint within another application (e.g., a Rails app)

![](https://dl.dropboxusercontent.com/u/7949088/notes-cli/notes-web2.png)

### As a standalone server:

Once the gem is installed, you can start a server with the `notes server` command, run from the directory
you wish to search in. The port can be customized with the `-p` flag (e.g. `notes server -p 8000`). 
The default port is 9292.

### Mounted in a Rails application:

Notes can expose its web interface as part of a host application. First, add `notes-cli` as a dependency in your Gemfile and run `bundle install`. Next, add the following to `config/routes.rb`:

```ruby
require 'notes-cli/web'

mount Notes::Web => '/notes'
```

Now, after starting a server normally, you can browse to `'/notes'` (or whichever URL you chose) in your application
to access the web interface.


## Using the CLI

Usage: `notes [DIRECTORY=. | FILES=<...>] [-f FLAGS] [-e EXCLUDES]`

### OPTIONS:
```
-f, --flags    # List of custom annotations, ex: '-f broken refactor' (case insensitive)
-e, --exclude  # List of directories to ignore, ex: '-e tmp/ log/'
-h, --help     # Display the help menu
```

### EXAMPLES:
```
notes                 # Show default annotations for all files in current directory (default)
notes app/ -f broken  # Only examine files in the app/ directory and add the 'broken' flag
notes -e tmp/ log/    # Ignore any files in tmp/ or log/
notes one.rb two.rb   # Show default annotations for one.rb and two.rb
```

A sample run might look like the following:
```
$ notes src/ -f failing

app/models/user.rb:
  ln 2: # TODO: Condense this eventually
  ln 34: # OPTIMIZE: This can be prettier

test/unit/group.rb
  ln 72: # FAILING
```

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes (and add some tests!) and commit (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pulll Request
