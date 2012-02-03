fs        = require 'fs'
should    = require 'should'
highlight = require '../src/highlight'

describe "highlight()", ->
  files = fs.readdirSync "./test/cases"
  for file in files
    continue unless /\.txt$/.test file
    
    testCase  = file.split(".")[0]
    codeFile  = "./test/cases/#{ file }"
    ruleFile  = "./test/cases/#{ testCase }.rules.json"
    tokenFile = "./test/cases/#{ testCase }.tokens.json"
    
    code                = fs.readFileSync(codeFile).toString()
    rules               = JSON.parse fs.readFileSync ruleFile
    correctTokensByLine = JSON.parse fs.readFileSync tokenFile
    highlight.addScopes rules
    
    
    do (code, rules, correctTokensByLine, testCase) ->
      it "parses #{file} correctly", ->
        actualTokensByLine = highlight code, "Test-#{testCase}", format: "json"
        
        for i, actualLine of actualTokensByLine
          actualLine.should.have.lengthOf correctTokensByLine[i].length
          for j, token of actualLine
            correctToken = correctTokensByLine[i][j]
            token.text.should.eql correctToken.text
            token.type.should.eql correctToken.type
