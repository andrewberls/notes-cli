## Notes - A tool for managing source code annotations

Notes is a command-line tool for tracking source code annotations such as TODO or FIXME. A numbered line will be printed for each annotation found in all examined files.

Default annotations are: __TODO__, __FIXME__, and __OPTIMIZE__. Custom annotations or directories to exclude can be specicified with command line arguments, detailed further.


### INSTALLATION:
`gem install notes-cli`

This will install the `notes` executable which will run the script and print found annotations.

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
