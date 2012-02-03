# Stratus:Color

[![Build Status](https://secure.travis-ci.org/stratuseditor/stratus-color.png)](http://travis-ci.org/stratuseditor/stratus-color)

It works from the command line, or the [browser][browserify],
and is used by [Stratus Editor][stratus].

Syntax languages are installed using [stratus-bundle][stratus-bundle].

## Install
Be sure you have [stratus-bundle][stratus-bundle].

    npm install -g stratus-color


## CLI

Writes highlighted version of somefile.rb to ./somefile.rb.html,
**including** the CSS for the theme.

    $ stratus-color --file somefile.rb -s

Writes highlighted version of somefile.rb to ./somefile.rb.html,
**without** the CSS for the theme.

    $ stratus-color --file somefile.rb


## API
### color(text, rules, context)

Highlight a string

    color = require 'stratus-color'
    
    code = """def hello()
      puts "Hello, world"
    end"""
    
    color code, "Ruby"
    # =>
    # "<div>... the highlighted code ...</div>"
    
    color code, "Ruby", format: "json"
    # =>
    # [ [... list of tokens for line 0 ...]
    # , [... line 1 ...]
    # , [...]
    # ]

### color.file(path, options?, callback)

Highlight a file

    color.file "path/to/file.rb", (err, html) ->
      # ...


## [List of syntaxes](http://stratuseditor.com/bundles#Existing+bundles)

## [Writing syntaxes](http://stratuseditor.com/bundles#Writing+bundles)

# License
See LICENSE.

[browserify]:     https://github.com/substack/node-browserify
[stratus]:        http://stratuseditor.com/
[stratus-bundle]: https://github.com/stratuseditor/stratus-bundle
