fs         = require 'fs'
path       = require 'path'
bundle     = require 'stratus-bundle'
highlight  = require './highlight'
theme      = require './theme'
standalone = require './standalone'

# Public: Same as highlight, but for the server-side.
# 
# If a stratus-bundle named `languageName` is installed, this saves
# you from having to addScopes manually.
# 
# Parameters and return value are the sames as for 
# highlight() in _highlight.coffee_.
module.exports = srvHighlight = (text, languageName, options = {}) ->
  if !highlight.hasScope languageName
    language = bundle languageName
    highlight.addScopes language.syntax
  
  return highlight text, languageName, options


# Extend exports.
for k, v of highlight
  srvHighlight[k] = v


srvHighlight.css = theme

# Public: Highlight the file by its path. If no language name is
# explicitly given, stratus-bundle will try to identify it.
# 
# file     - The path of a file to highlight.
# options  - An object of extras (optional).
#            * language   - string
#            * standalone - boolean
#            * theme      - a theme object or string name
# callback - Receives `(err, html)`, where html is a string.
# 
# Examples
# 
#   highlight.file "path/to/file.rb", (err, html) ->
#   highlight.file "path/to/file.rb",
#     language:   "Ruby.Rails.Model"
#     standalone: true
#   , (err, html) ->
#     # ...
# 
srvHighlight.file = (file, options, callback) ->
  # `options` (the middle argument) is optional, callback is not.
  [callback, options] = [options, callback] if !callback
  options           ||= {}
  options.theme     ||= "Idlefingers" if options.standalone
  
  text     = fs.readFileSync(file).toString()
  complete = (err, language) ->
    return callback err if err
    html = srvHighlight text, language
    if options.standalone
      standalone html, options.theme, file, (html) ->
        # Output
        return callback null, html
    else
      # Output
      return callback null, html
  
  if options.language
    complete null, options.language
  else
    bundle.identify file, (err, language) ->
      complete err, language
  return

