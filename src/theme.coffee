fs     = require 'fs'
path   = require 'path'
stylus = require 'stylus'

# Convert a theme to css.
# 
# theme   - A theme object or the string name of a theme.
# options - An optional object with keys:
#           * root      - The root selector name.
#           * cursor    - The CSS selector for the cursor.
#           * selection - The CSS selector for the selection.
# 
# Examples
# 
#   css = theme
#     background: "#323232"
#     color:      "white"
#     search: "#525252"
#     "current-search": "white"
#     "line-numbers":
#       background: "#2f2f2f"
#       color:      "#444444"
#    
#     "current-line": "#353637"
#     selection: "rgba(90, 100, 126, 0.35)"
#   
#     "highlight":
#        constant: { color: "#b7dff8" }
#        # ...
# 
#   css = theme "Idlefingers"
# 
# Return a CSS string.
module.exports = themeToCSS = (theme, options={}) ->
  {root, cursor, selection} = options
  root ?= "stratus-color"
  
  theme = getTheme theme if typeof theme == "string"
  css   = """
    .#{root} {
      #{objToCSSProps(theme, ["background", "color"])} }
    
    .#{root} *::selection {
      background: #{ theme.selection }; }
    .#{root} li::selection {
      background: #{ theme.selection }; }
  
    .hi-search    { #{objToCSSProps(theme.search)} }
    .hi-emphasize { #{objToCSSProps(theme.emphasize)} }
    
    .#{root}-gutter {
      #{objToCSSProps(theme["line-numbers"])} }
    .#{root}-gutter > span.current-middle {
      #{objToCSSProps(theme["current-line-numbers"])} }
    .#{root}-gutter > span.current-top {
      border-width: 1px 0px 0px;
      border-style: solid;
      margin:       -1px 0px 0px;
      #{objToCSSProps(theme["current-line-numbers"])} }
    .#{root}-gutter > span.current-bottom {
      border-width: 0px 0px 1px;
      border-style: solid;
      margin:       0px 0px -1px;
      #{objToCSSProps(theme["current-line-numbers"])} }
    .#{root}-gutter > span.current {
      border-width: 1px 0px;
      border-style: solid;
      margin:       -1px 0px;
      #{objToCSSProps(theme["current-line-numbers"])} }
    """
  
  css += ".#{selection} { background: #{theme.selection}; }" if selection
  css += ".#{cursor}    { background: #{theme.cursor}; }" if cursor
  
  for scope, styles of theme.highlight
    cssClass = scope.replace /[.]/g, "-"
    values   = objToCSSProps styles
    css     += ".hi-#{cssClass} { #{values} }\n"
  return css


# Public: The directory containing installed Stratus themes.
themeToCSS.dir = dir  = "#{process.env.HOME}/.stratus/themes"
themeToCSS.defaultDir = defaultDir = "#{__dirname}/../themes"

# Get the primary CSS string. This applies regardless of the theme.
# 
# callback - Receives the CSS string.
# 
# No return.
themeToCSS.mainCSS = mainCSS = (callback) ->
  mainStyl = fs.readFileSync "#{__dirname}/../index.styl"
  stylus(mainStyl.toString())
    .set('filename', "stratus-color/index.styl")
    .render (err, actual) ->
      callback actual
  return

# Internal: Convert an object to CSS.
# 
# styles - An object, where keys are CSS property names.
# 
# Examples
# 
#   objToCSSProps
#     color:              "#fff"
#     "background-color": "#000"
#   # => "color: #fff;background-color: #000;"
# 
#   objToCSSProps
#     color:              "#fff"
#     "background-color": "#000"
#   , ["color"]
#   # => "color: #fff;"
# 
objToCSSProps = (styles, keys = null) ->
  css = ""
  if !keys
    for propName, propVal of styles
      css += "#{propName}: #{propVal};"
  else
    for propName in keys
      css += "#{propName}: #{styles[propName]};"
  return css


# Resolve the given theme to an object.
# 
# themeName - Either the name of a built-in theme, such as "Idlefingers",
#             or the path to a theme.json file.
# 
# Return a theme object.
themeToCSS.getTheme = getTheme = (themeName) ->
  themePath = "#{ dir }/#{ themeName }.json"
  altPath   = "#{ defaultDir }/#{ themeName }.json"
  if path.existsSync themeName
    return JSON.parse fs.readFileSync themeName
  else if path.existsSync(themePath)
    return JSON.parse fs.readFileSync themePath
  else if path.existsSync(altPath)
    return JSON.parse fs.readFileSync altPath
  else
    throw new Error "No theme named '#{themeName}' found."

