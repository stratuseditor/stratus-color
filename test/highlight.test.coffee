should    = require 'should'
highlight = require '../src/highlight'

describe "highlight", ->
  rubyRules = [
    { token: "comment"
    , match: "[#].*(?=\n)"
    }
    { token:    "entity.builtin"
    , keywords: "new|require|require_relative"
    }
    { token: "string"
    , begin: "'"
    , end:   "'"
    }
  ]
  rubyCode = "# This is some nifty code\n" +
             "require 'somegem'\n" +
             "x = Something.new\n"
  highlight.addScopes { Ruby: rubyRules }
  
  describe "highlight", ->
    describe "html format", ->
      html = highlight rubyCode, "Ruby", format: "html"
      
      it "has the class 'stratus-color'", ->
        html.should.match /^<div class='stratus-color'>/
      
      it "plaintext has no class", ->
        html.should.match /<span>x &#61; Something.<\/span>/
        
      it "escapes html", ->
        html.should.match /&#61;/
        html.should.not.match />[^<>]*[=][^<>]</
      
      for ln in [1..4]
        do (ln) ->
          it "has a line number #{ ln }", ->
            html.should.match new RegExp "<span>#{ ln }</span>"
      
      it "includes the gutter", ->
        html.should.include "<div class='stratus-color-gutter'>"
    
    
    describe "html format without the gutter", ->
      html = highlight rubyCode, "Ruby",
        format: "html"
        gutter: false
      
      it "include the gutter html", ->
        html.should.not.match /<div class='stratus-color-gutter'>/
      
      it "does not have a line number 5", ->
        html.should.not.include "<span>1</span>"
        html.should.not.include "stratus-color-gutter"
  
  
  describe ".tokenize", ->
    correctTokens = [
      [ { type: "comment", text: "# This is some nifty code" }
      ]
      [ { type: "entity.builtin", text: "require" }
        { type: "", text: " "}
        { type: "string", text: "'somegem'" }
      ]
      [ { type: "", text: "x = Something." }
        { type: "entity.builtin", text: "new" }
        { type: "", text: "\n" }
      ]
    ]
    
    it "returns the stack and tokens", ->
      lines = rubyCode.split "\n"
      for i, line of lines
        data = highlight.tokenize line, "Ruby"
        
        describe ".stack", ->
          it "is ['Ruby']", ->
            data.stack.should.have.length(1)
            data.stack[0].should.eql "Ruby"
        
        describe ".tokens", ->
          it "is correct", ->
            for j, token of data.tokens
              token.should.include.object correctTokens[i][j]
    
  
  describe ".addScopes", ->
    it "adds the scopes to highlight.scopes", ->
      highlight.addScopes Cheese: []
      highlight.scopes.Cheese.should.be.empty
  
  
  describe ".hasScope", ->
    describe "when it has the scope", ->
      it "is true", ->
        highlight.addScopes Crackers: []
        highlight.hasScope("Crackers").should.be.true
    
    describe "when it does not have the scope", ->
      it "is false", ->
        highlight.hasScope("blablabla").should.be.false
  
  
  describe ".matchOnce", ->
    describe "a regex rule", ->
      rule = highlight.compileRule
        token: "comment"
        match: "[#].*(?=\n)"
      text  = "# some comment\n"
      match = highlight.matchOnce rule, text, ""
      
      it "returns an object", ->
        match.should.be.a "object"
      
      for prop in ["token", "next", "length"]
        it "has the property #{prop}", ->
          match.should.have.property prop
      
      describe "token", ->
        {token} = match
        it "name is the same as the rule's token", ->
          token.type.should.eql rule.token
        
        it "text does not include a newline", ->
          token.text.should.eql "# some comment"
      
      describe "length", ->
        it "is the length of the entire match", ->
          match.length.should.eql "# some comment".length
      
      describe "next", ->
        it "is undefined", ->
          should.not.exist match.next
    
    describe "a non-matching regex rule", ->
      rule = highlight.compileRule
        token: "comment"
        match: "[#].*(?=\n)"
      text  = " # some comment\n"
      match = highlight.matchOnce rule, text, ""
      
      it "is null", ->
        should.not.exist match
    
    describe "keyword rule", ->
      rule = highlight.compileRule
        token:    "entity.builtin"
        keywords: "new|require|require_relative"
      
      describe "after whitespace", ->
        text  = "new "
        match = highlight.matchOnce rule, text, " "
        
        it "matches", ->
          match.should.be.a "object"
      
      describe "after a letter", ->
        text  = "new "
        match = highlight.matchOnce rule, text, "X"
        
        it "does not match", ->
          should.not.exist match
      
      describe "followed by a letter", ->
        text  = "neww"
        match = highlight.matchOnce rule, text, " "
        
        it "does not match", ->
          should.not.exist match
  
  
  describe ".compileRule", ->
    describe "a basic regexp rule", ->
      rule =
        token: "comment"
        match: "[#].*(?=\n)"
      compiled = highlight.compileRule rule
      
      it "is an object", ->
        compiled.should.be.a "object"
      
      it "has an identical `token` property", ->
        compiled.should.have.property "token", rule.token
      
      it "has a `match` property", ->
        compiled.should.have.property "match"
      
      describe "the `match` property", ->
        it "matches the start", ->
          compiled.match.test("# bla\n").should.be.true
        
        it "doesnt match anywhere else in the string", ->
          compiled.match.test(" # bla\n").should.be.false
      
    
    describe "a begin/end rule", ->
      rule =
        token: "comment"
        begin: "\n=begin"
        end:   "\n=end"
      compiled = highlight.compileRule rule
      
      it "has a string `next` property", ->
        compiled.next.should.be.a "string"
      
      it "has a `regex` property", ->
        compiled.match.test("\n=begin bla").should.be.true
      
      
      describe "the new context", ->
        context = highlight.scopes[compiled.next]
        
        it "exists", ->
          context.should.be.a "object"
        
        describe "the first rule", ->
          first = context[0]
          
          it "is an end rule", ->
            first.next.should.be.false
          
          it "has a `regex` property", ->
            first.match.test("\n=end bla").should.be.true
          
          it "has the same `token` as the original rule", ->
            first.token.should.eql rule.token
        
        describe "the last rule", ->
          last = context[context.length - 1]
          
          it "has a catch-all rule at the end", ->
            last.isCatchAll.should.be.true
          
          it "has the same token type as the `begin` rule", ->
            last.token.should.eql rule.token
    
    
    describe "a begin/end rule with included rules", ->
      rule =
        token: "keyword"
        begin: "\\sclass\\s"
        end:   "\n"
        include:
          [ { token: "entity.class"
            , match: "\\w+"
            }
          , { token: "keyword.operator"
            , match: "[<]"
            }
          ]
      compiled = highlight.compileRule rule
      
      describe "the new context", ->
        context = highlight.scopes[compiled.next]
        
        it "has 4 elements", ->
          context.should.have.lengthOf(4)
        
        it "compiled the child rules", ->
          context[1].match.test.should.be.a "function"
    
    
    describe "a begin/end rule with an included language", ->
      rule =
        token:   "keyword.operator"
        begin:   "[<]%"
        end:     "%[>]"
        include: "@Ruby.Rails.View"
      compiled = highlight.compileRule rule, "HTML.ERB"
      
      describe "the new context", ->
        context = highlight.scopes[compiled.next]
        
        it "has an `include` property", ->
          context[1].include.should.eql "@Ruby.Rails.View"
        
        it "has a `self` property", ->
          context[1].self.should.eql "HTML.ERB"
    
    
    describe "a begin/end rule with an included repo", ->
      rule =
        token:   "keyword.operator"
        begin:   "[<]%"
        end:     "%[>]"
        include: "#some-repo"
      compiled = highlight.compileRule rule, "HTML.ERB"
      
      describe "the new context", ->
        context = highlight.scopes[compiled.next]
        
        it "has an `include` property", ->
          context[1].include.should.eql "HTML.ERB#some-repo"
        
        it "has a `self` property", ->
          context[1].self.should.eql "HTML.ERB"
    
    
    describe "a keyword rule", ->
      rule =
        token:    "entity.builtin"
        keywords: "new|require|require_relative"
      compiled = highlight.compileRule rule
      
      it "has an `isKeyword` property", ->
        compiled.isKeyword.should.be.true
      
      describe "the match property", ->
        it "has a `match` property", ->
          compiled.should.have.property "match"
        
        it "matches a standalone word", ->
          compiled.match.test("new ").should.be.true
        
        it "doesn't match a non-word", ->
          compiled.match.test("neww").should.be.false
      

