should    = require 'should'
bundle    = require 'stratus-bundle'
highlight = require '../src'

bundleDir  = require.resolve("stratus-bundle").split("/")[0..-2].join("/")
bundle.dir = "#{bundleDir}/test/cases"

describe "highlight", ->
  describe ".file", ->
    describe "without an explicit language", ->
      it "identifies the file", (done) ->
        highlight.file "#{__dirname}/fixtures/file.rb", (err, html) ->
          should.not.exist err
          html.should.be.a "string"
          done()
    
    describe "standalone", ->
      it "passes standalone html", (done) ->
        highlight.file "#{__dirname}/fixtures/file.rb",
          standalone: true
        , (err, html) ->
          should.not.exist err
          html.should.include "</html>"
          done()
    
    describe "a file that cannot be identified", ->
      it "passes an error", (done) ->
        highlight.file "#{__dirname}/fixtures/mysteryfile", (err, html) ->
          err.should.be.an.instanceof Error
          done()
