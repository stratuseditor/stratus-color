###

Note: "Token" refers to an object with properties "text" and "type".

###

html = require './renderers/html'

# Create some tokens for the given text.
# 
# text    - The string to be highlighted.
# context - The starting context.
# options - An hash. Keys:
#           * format - Default: "html", "json".
# 
# Examples
# 
#   highlight "def foo()\n  true\nend", "Ruby"
#   # => "..."
# 
# Returns based on format:
# 
#   * html: html string
#   * json: list of token objects by line
# 
# Each token has the properties `type` and `text`.
module.exports = highlight = (text, stack, options = {}) ->
  lines        = text.split "\n"
  tokensByLine = []
  
  for line in lines
    {tokens, stack} = tokenize "\n#{line}\n", stack
    tokensByLine.push tokens
  
  if !options.format || options.format == "html"
    return html tokensByLine, options
  else if options.format == "json"
    return tokensByLine
  else
    throw new Error "Unknown format: '#{ options.format }'"


# Create some tokens for the given text.
# 
# text    - The string to be highlighted.
# context - The starting context.
# 
# Return a list of tokens.
# Each token has the properties `type` and `text`.
highlight.tokenize = tokenize = (text, stack) ->
  stack        = [stack] if typeof(stack) == "string"
  tokens       = []
  charIndex    = 0
  currentRules = null
  
  addToken = (token) ->
    # The tokens have the same type, so combine them.
    if (prevToken = last(tokens)) and prevToken.type == token.type
      prevToken.text += token.text
    else
      tokens.push token
  
  setCurrentRules = ->
    currentRules = highlight.scopes[last(stack)]
  setCurrentRules()
  
  while text[charIndex]
    subText  = text.slice charIndex
    isMatch  = false
    prevChar = text[charIndex - 1]
    
    for rule in currentRules
      if match = matchOnce rule, subText, prevChar
        # A single token.
        if match.token
          addToken match.token if match.token.text
        # Many tokens.
        else
          for token in match.tokens
            addToken token
          
        charIndex += match.length
        
        if match.next == false
          stack.pop()
          setCurrentRules()
        else if match.next
          stack.push match.next
          setCurrentRules()
        
        isMatch = true
        break
    
    if !isMatch and subText[0] != "\n"
      addToken { type: "", text: subText[0] }
    if !isMatch
      charIndex++
  
  return {stack, tokens}

highlight.scopes = {}

highlight.html   = html.tokensToHtml
highlight.escape = html.escape

# Public: Add the syntax highlighter rules to the repo.
# 
# scopes - An object keyed by the context name, and the value
#          is a list of rules. All but one of the keys (the
#          required one) must begin with a hash symbol.
# 
# No return value.
highlight.addScopes = (scopes) ->
  # Find the base scope (the non-repo one).
  baseScope = null
  for context, rules of scopes
    if context[0] != "#"
      baseScope = context
      break
  
  
  # Create and compile the scopes
  for context, rules of scopes
    # Repository: `rules` is actually a single rule.
    if context[0] == "#"
      context = baseScope + context
      highlight.scopes[context] = compileRule rules, baseScope
    # Regular
    else
      highlight.scopes[context] = for subRule in rules
        compileRule subRule, baseScope
  
  return

# Public: Return whether or not a scope has been loaded with the given name.
# 
# scope - A string such as "Ruby".
# 
# Return boolean.
highlight.hasScope = (scope) ->
  return !!highlight.scopes[scope]

# 
# 
# rule     - The compiled rule to test with.
# text     - The text to test.
# stack    - The current scopes.
# prevChar - The char in the text being highlighted just before `subText`.
#            This is used for a fake lookbehind to match keywords.
# 
# Return an object with properties:
# * token or tokens - A single token (or a list of tokens).
# * next   - The scope that was entered. This should be pushed
#            onto the stack.
# * length -  The match length.
highlight.matchOnce = matchOnce = (rule, text, prevChar) ->
  # Catch all
  if rule.isCatchAll == true
    return {
      length: 1
      token:
        type: rule.token
        text: text[0].replace(/\n/g, "")
    }
    
  # Self reference
  else if rule.include == "$self"
    for subRule in highlight.scopes[rule.self]
      return m if m = matchOnce subRule, text, prevChar
  
  # Language or repository include.
  else if /[@#]/.test rule.include
    subRules = highlight.scopes[rule.include.replace(/^@/, "")]
    if subRules instanceof Array
      for subRule in subRules
        return m if m = matchOnce subRule, text, prevChar
    # Repo: single-rule include
    else
      return m if m = matchOnce subRules, text, prevChar
  
  # Keyword rule.
  else if rule.isKeyword
    return null if prevChar && /\w/.test prevChar
    match = rule.match.exec text
    return null unless match
    token =
      type: rule.token
      text: match[0].replace(/\n/g, "")
    {length} = match[0]
    {next}   = rule
    return {token, length, next}
    
  # Regex match.
  else if rule.match
    return null if rule.behind && !rule.behind.test(prevChar)
    match    = rule.match.exec text
    return null unless match
    {length} = match[0]
    {next}   = rule
    token =
      type: rule.token
      text: match[0].replace(/\n/g, "")
    return {token, length, next}
  
  return null


# Compile the pretty rule into one that can be used by the parser.
# 
# Return an object with the following keys:
# * token     - 
# * next      - The scope to enter after this rule is matched.
# * isKeyword -
# * include   - "@Language", "$self", "Language#repo", ...
# * self
# * isCatchAll
# * behind
highlight.compileRule = compileRule = (rule, self) ->
  newRule = {token: rule.token || ""}
  
  if rule.match
    newRule.match = new RegExp "^(?:#{ rule.match })"
    if rule.behind
      newRule.behind = new RegExp rule.behind
  else if rule.begin
    cId = "_" + contextId++
    # The begin rule
    newRule.match = new RegExp "^(?:#{ rule.begin })"
    newRule.next  = cId
    
    compiledRules = []
    # The end rule.
    # This is first to ensure its precidence over the include.
    compiledRules.push
      token: rule.token
      match: new RegExp "^(?:#{ rule.end })"
      next:  false # false indicates that we should leave the context
    
    # Includes
    # Special include (language, repo, $self).
    if rule.include and typeof(rule.include) == "string"
      # Repo
      incScope = rule.include
      incScope = self + incScope if rule.include[0] == "#"
      compiledRules.push { include: incScope, self }
    # Rule include.
    else
      for subRule in (rule.include || [])
        compiledRules.push compileRule(subRule, self)
      
      compiledRules.push { token: rule.token, isCatchAll: true }
    
    highlight.scopes[cId] = compiledRules
  
  # Include repo rule.
  else if rule.include
    newRule = { include: self + rule.include, self }
  
  else if rule.keywords
    newRule.match     = new RegExp "^(?:#{ rule.keywords })(?=[^\\w]|\n)"
    newRule.isKeyword = true
  
  return newRule



contextId = 0

# Helpers
last = (arr) -> arr[arr.length - 1]


