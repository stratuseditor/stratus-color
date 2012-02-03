path   = require 'path'
should = require 'should'
theme  = require '../src/theme'

describe "theme", ->
  describe "()", ->
    css = theme
      background:       "white"
      color:            "black"
      search:           {background: "#444"}
      "current-search": {background: "#aaa"}
      "line-numbers":
        background: "#2f2f2f"
        color:      "#444"
      
      highlight:
        "constant":         { "color": "#b7dff8" }
        "constant.builtin": { "color": "#6c99bb" }
        "constant.numeric": { "color": "#6c99bb" }
    
    it "returns a string", ->
      css.should.be.a "string"
    
    it "defines the background", ->
      css.should.match /background: white;/
    
    it "defines the foreground", ->
      css.should.match /color: black;/
    
    describe "the `highlight` values", ->
      it "includes css classes for each of the scopes", ->
        css.should.match /[.]hi-constant {/
        css.should.match /[.]hi-constant-builtin {/
        css.should.match /[.]hi-constant-numeric {/
      
      it "includes css properties", ->
        css.should.match /color: #b7dff8/
        css.should.match /color: #6c99bb/
        css.should.match /color: #6c99bb/
  
  
  describe ".getTheme", ->
    describe "passing a built-in theme", ->
      themeObj = theme.getTheme "Idlefingers"
      
      it "returns an object", ->
        themeObj.should.be.a "object"
    
    describe "passing the path to a theme", ->
      themeObj = theme.getTheme path.resolve "#{__dirname}/../themes/Idlefingers.json"
      
      it "returns an object", ->
        themeObj.should.be.a "object"
    
    describe "passing a non-existant theme", ->
      it "throws an error", ->
        should.throws ->
          theme.getTheme path.resolve "SomeRandomTheme"

