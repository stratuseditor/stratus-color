highlight = require './'
theme     = require './theme'


# Generate a standalone HTML file to display the highlighted code.
# 
# body  - The html of the highlighted code.
# theme - A theme object. The theme's CSS is included in the page.
# title - The name of the file that the code is from. This is used in the
#        `<title>` tag.
# 
# Return an html string.
module.exports = (body, themeObj, title, callback) ->
  theme.mainCSS (css) ->
    return callback """
    <html>
      <head>
        <title>#{title} - Stratus:Color</title>
        <style>
          .stratus-color {
            position: fixed;
            top: 0px;
            left: 0px;
            right: 0px;
            bottom: 0px; }
          #{ css }
          #{ theme(themeObj, true) }
        </style>
      </head>
      <body>#{body}</body>
    </html>"""
  return
