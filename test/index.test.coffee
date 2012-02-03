should    = require 'should'
highlight = require '../'

describe "highlight", ->
  describe ".file", ->
    describe "without an explicit language", ->
      it "identifies the file", (done) ->
        highlight.file "./test/fixtures/file.rb", (err, html) ->
          should.not.exist err
          html.should.be.a "string"
          done()
    
    describe "standalone", ->
      it "passes standalone html", (done) ->
        highlight.file "./test/fixtures/file.rb",
          standalone: true
        , (err, html) ->
          should.not.exist err
          html.should.include "</html>"
          done()
    
    describe "a file that cannot be identified", ->
      it "passes an error", (done) ->
        highlight.file "./test/fixtures/mysteryfile", (err, html) ->
          err.should.be.an.instanceof Error
          done()