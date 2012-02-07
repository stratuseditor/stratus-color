{exec} = require 'child_process'
should = require 'should'
bundle = require 'stratus-bundle'
bundle.testDir()

rubyCode = "def hi()\n  true\nend"
bin      = "./bin/stratus-color.js"

describe "stratus-color.js", ->
  describe "pass code to STDIN", ->
    output = null
    before (done) ->
      exec "echo '#{rubyCode}' | #{bin} -l Ruby",
      (err, stdout, stderr) ->
        throw err if err
        throw new Error(stdout) if stderr
        output = stdout
        done()
    
    it "prints the highlighted code", ->
      output.should.include "end</span>"
      output.should.include "hi-keyword"
      output.should.include "hi-constant-builtin"
    
    it "numbers the lines", ->
      output.should.include "<span>2</span"
  
  
  describe "disable gutter", ->
    output = null
    before (done) ->
      exec "echo '#{rubyCode}' | #{bin} -l Ruby -N",
      (err, stdout, stderr) ->
        throw err if err
        throw new Error(stdout) if stderr
        output = stdout
        done()
    
    it "prints the highlighted code", ->
      output.should.include "end</span>"
      output.should.include "hi-keyword"
      output.should.include "hi-constant-builtin"
    
    it "doesn't numbers the lines", ->
      output.should.not.include "<span>2</span"
