should     = require 'should'
standalone = require '../src/standalone'

describe "standalone", ->
  describe "()", ->
    standalone "<span>Something</span>",
      background: "white"
      color: "black"
      highlight:
        builtin:            "red"
        "builtin.constant": "blue"
    , "file.rb", (html) ->
      it "produces html", ->
        html.should.match /^<html/
      
      it "includes the code", ->
        html.should.include "<span>Something</span>"
      
      it "the page title includes the file name", ->
        html.should.match /<title>[^<>]*file.rb[^<>]*<\/title>/
      
      it "includes CSS", ->
        html.should.include "<style>"
      
      it "includes the theme", ->
        html.should.include "background: white;"
