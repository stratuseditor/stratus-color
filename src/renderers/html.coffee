# Render the tokens as html.
# 
# tokensByLine - A list of lists of tokens. Each inner list is a line of code.
# options      - Optional configuration
#                * gutter - Boolean, whether or not to display
#                           line numbers. Default: true.
# 
# Return the html string.
module.exports = renderHtml = (tokensByLine, options = {}) ->
  lineHtml = ""
  for tokens in tokensByLine
    lineHtml += "<li>#{ tokensToHtml(tokens) }</li>"
  
  gutter = if options.gutter == false
    ""
  else
    lineCount = tokensByLine.length
    html      = "<div class='stratus-color-gutter'>"
    for i in [1..lineCount]
      html += "<span>#{i}</span>"
    html + "</div>"
  
  html  = "<div class='stratus-color'>"
  html += gutter
  html += "<ul>#{lineHtml}</ul></div>"
  return html


renderHtml.tokensToHtml = tokensToHtml = (tokens) ->
  (tokenToHtml token for token in tokens).join ""

# Render the token as html.
# 
# token - An object with properties "type" and "text".
# 
# Examples
# 
#   tokenToHtml
#     type: "builtin.constant"
#     text: "CHEESE"
#   # => "<span class='hi-builtin hi-builtin-constant'>CHEESE</span>"
# 
# Return a string.
tokenToHtml = (token) ->
  cssClass = tokenTypeToClass token.type
  text     = escapeForHTML token.text
  return "<span#{cssClass}>#{ text }</span>"


# Change a token type into the css classes used to color it.
# 
# type - A token type, such as "builtin.constant" or "string".
# 
# Examples
# 
#   tokenTypeToClass "builtin.constant"
#   # => "hi-builtin hi-builtin-constant"
# 
#   tokenTypeToClass "string"
#   # => "hi-string"
# 
# Return a space-delimited list of the css classes to apply to the element.
tokenTypeToClass = (type) ->
  return "" if !type
  scopes     = type.split "."
  cssClasses = []
  lastClass  = "hi"
  for scope in scopes
    lastClass = "#{ lastClass }-#{ scope }"
    cssClasses.push lastClass
  return " class='#{ cssClasses.join(" ") }'"

renderHtml.escape = escapeForHTML = (text) ->
  text.replace(/[&]/g, "&amp;")
    .replace(/[<]/g, "&lt;")
    .replace(/[>]/g, "&gt;")
    .replace(/[=]/g, "&#61;")
    


