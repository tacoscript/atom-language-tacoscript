fs = require 'fs'
path = require 'path'

describe "TacoScript grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-tacoscript")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.taco")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.taco"

  it "tokenizes classes", ->
    {tokens} = grammar.tokenizeLine("class Foo")

    expect(tokens[0]).toEqual value: "class", scopes: ["source.taco", "meta.class.taco", "storage.type.class.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[2]).toEqual value: "Foo", scopes: ["source.taco", "meta.class.taco", "entity.name.type.class.taco"]

    {tokens} = grammar.tokenizeLine("subclass Foo")
    expect(tokens[0]).toEqual value: "subclass Foo", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("[class Foo]")
    expect(tokens[0]).toEqual value: "[", scopes: ["source.taco", "meta.brace.square.taco"]
    expect(tokens[1]).toEqual value: "class", scopes: ["source.taco", "meta.class.taco", "storage.type.class.taco"]
    expect(tokens[2]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[3]).toEqual value: "Foo", scopes: ["source.taco", "meta.class.taco", "entity.name.type.class.taco"]
    expect(tokens[4]).toEqual value: "]", scopes: ["source.taco", "meta.brace.square.taco"]

    {tokens} = grammar.tokenizeLine("bar(class Foo)")
    expect(tokens[0]).toEqual value: "bar", scopes: ["source.taco", "entity.name.function.taco"]
    expect(tokens[1]).toEqual value: "(", scopes: ["source.taco", "meta.brace.round.taco"]
    expect(tokens[2]).toEqual value: "class", scopes: ["source.taco", "meta.class.taco", "storage.type.class.taco"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[4]).toEqual value: "Foo", scopes: ["source.taco", "meta.class.taco", "entity.name.type.class.taco"]
    expect(tokens[5]).toEqual value: ")", scopes: ["source.taco", "meta.brace.round.taco"]

  it "tokenizes named subclasses", ->
    {tokens} = grammar.tokenizeLine("class Foo extends Bar")

    expect(tokens[0]).toEqual value: "class", scopes: ["source.taco", "meta.class.taco", "storage.type.class.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[2]).toEqual value: "Foo", scopes: ["source.taco", "meta.class.taco", "entity.name.type.class.taco"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[4]).toEqual value: "extends", scopes: ["source.taco", "meta.class.taco", "keyword.control.inheritance.taco"]
    expect(tokens[5]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[6]).toEqual value: "Bar", scopes: ["source.taco", "meta.class.taco", "entity.other.inherited-class.taco"]

  it "tokenizes anonymous subclasses", ->
    {tokens} = grammar.tokenizeLine("class extends Foo")

    expect(tokens[0]).toEqual value: "class", scopes: ["source.taco", "meta.class.taco", "storage.type.class.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[2]).toEqual value: "extends", scopes: ["source.taco", "meta.class.taco", "keyword.control.inheritance.taco"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.taco", "meta.class.taco"]
    expect(tokens[4]).toEqual value: "Foo", scopes: ["source.taco", "meta.class.taco", "entity.other.inherited-class.taco"]

  it "tokenizes instantiated anonymous classes", ->
    {tokens} = grammar.tokenizeLine("new class")

    expect(tokens[0]).toEqual value: "new", scopes: ["source.taco", "meta.class.instance.constructor", "keyword.operator.new.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco", "meta.class.instance.constructor"]
    expect(tokens[2]).toEqual value: "class", scopes: ["source.taco", "meta.class.instance.constructor", "storage.type.class.taco"]

  it "tokenizes instantiated named classes", ->
    {tokens} = grammar.tokenizeLine("new class Foo")

    expect(tokens[0]).toEqual value: "new", scopes: ["source.taco", "meta.class.instance.constructor", "keyword.operator.new.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco", "meta.class.instance.constructor"]
    expect(tokens[2]).toEqual value: "class", scopes: ["source.taco", "meta.class.instance.constructor", "storage.type.class.taco"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.taco", "meta.class.instance.constructor"]
    expect(tokens[4]).toEqual value: "Foo", scopes: ["source.taco", "meta.class.instance.constructor", "entity.name.type.instance.taco"]

    {tokens} = grammar.tokenizeLine("new Foo")

    expect(tokens[0]).toEqual value: "new", scopes: ["source.taco", "meta.class.instance.constructor", "keyword.operator.new.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco", "meta.class.instance.constructor"]
    expect(tokens[2]).toEqual value: "Foo", scopes: ["source.taco", "meta.class.instance.constructor", "entity.name.type.instance.taco"]

  it "tokenizes annotations in block comments", ->
    lines = grammar.tokenizeLines """
      ###
        @foo - food
      @bar - bart
      """

    expect(lines[1][0]).toEqual value: '  ', scopes: ["source.taco", "comment.block.taco"]
    expect(lines[1][1]).toEqual value: '@foo', scopes: ["source.taco", "comment.block.taco", "storage.type.annotation.taco"]
    expect(lines[2][0]).toEqual value: '@bar', scopes: ["source.taco", "comment.block.taco", "storage.type.annotation.taco"]

  it "tokenizes this as a special variable", ->
    {tokens} = grammar.tokenizeLine("this")

    expect(tokens[0]).toEqual value: "this", scopes: ["source.taco", "variable.language.this.taco"]

  it "tokenizes variable assignments", ->
    {tokens} = grammar.tokenizeLine("a = b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a and= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "and=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a or= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "or=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a -= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "-=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a += b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "+=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a /= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "/=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a &= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "&=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a %= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "%=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a *= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "*=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a ?= b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]
    expect(tokens[1]).toEqual value: "?=", scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("a == b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: "==", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("false == b")
    expect(tokens[0]).toEqual value: "false", scopes: ["source.taco", "constant.language.boolean.false.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("true == b")
    expect(tokens[0]).toEqual value: "true", scopes: ["source.taco", "constant.language.boolean.true.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("null == b")
    expect(tokens[0]).toEqual value: "null", scopes: ["source.taco", "constant.language.null.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("this == b")
    expect(tokens[0]).toEqual value: "this", scopes: ["source.taco", "variable.language.this.taco"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.taco"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.taco"]

  it "tokenizes compound operators properly", ->
    compoundOperators = ["and=", "or=", "==", "!=", "<=", ">=", "<<=", ">>=", ">>>=", "<>", "*=", "%=", "+=", "-=", "&=", "^="]

    for compoundOperator in compoundOperators
      {tokens} = grammar.tokenizeLine(compoundOperator)
      expect(tokens[0]).toEqual value: compoundOperator, scopes: ["source.taco", "keyword.operator.taco"]

  it "tokenizes operators properly", ->
    operators = ["!", "%", "^", "*", "/", "~", "?", ":", "-", "--", "+", "++", "<", ">", "&", "&&", "..", "...", "|", "||", "instanceof", "new", "delete", "typeof", "and", "or", "is", "isnt", "not", "super"]

    for operator in operators
      {tokens} = grammar.tokenizeLine(operator)
      expect(tokens[0]).toEqual value: operator, scopes: ["source.taco", "keyword.operator.taco"]

  it "does not tokenize non-operators as operators", ->
    notOperators = ["(/=", "-->", "=>"]

    for notOperator in notOperators
      {tokens} = grammar.tokenizeLine(notOperator)
      expect(tokens[0]).not.toEqual value: notOperator, scopes: ["source.taco", "keyword.operator.taco"]

  it "does not confuse prototype properties with constants and keywords", ->
    {tokens} = grammar.tokenizeLine("Foo::true")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "true", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("Foo::on")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "on", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("Foo::yes")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "yes", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("Foo::false")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "false", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("Foo::off")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "off", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("Foo::no")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "no", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("Foo::null")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "null", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("Foo::extends")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.taco"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.taco", "keyword.operator.taco"]
    expect(tokens[3]).toEqual value: "extends", scopes: ["source.taco"]

  it "verifies that regular expressions have explicit count modifiers", ->
    source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'tacoscript.cson'), 'utf8')
    expect(source.search /{,/).toEqual -1

    source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'tacoscript (literate).cson'), 'utf8')
    expect(source.search /{,/).toEqual -1

  it "tokenizes embedded JavaScript", ->
    {tokens} = grammar.tokenizeLine("`;`")
    expect(tokens[0]).toEqual value: "`", scopes: ["source.taco", "string.quoted.script.taco", "punctuation.definition.string.begin.taco"]
    expect(tokens[1]).toEqual value: ";", scopes: ["source.taco", "string.quoted.script.taco", "constant.character.escape.taco"]
    expect(tokens[2]).toEqual value: "`", scopes: ["source.taco", "string.quoted.script.taco", "punctuation.definition.string.end.taco"]

    lines = grammar.tokenizeLines """
      `var a = 1;`
      a = 2
      """
    expect(lines[0][0]).toEqual value: '`', scopes: ["source.taco", "string.quoted.script.taco", "punctuation.definition.string.begin.taco"]
    expect(lines[0][1]).toEqual value: 'v', scopes: ["source.taco", "string.quoted.script.taco", "constant.character.escape.taco"]
    expect(lines[1][0]).toEqual value: 'a ', scopes: ["source.taco", "variable.assignment.taco", "variable.assignment.taco"]

  it "tokenizes functions", ->
    {tokens} = grammar.tokenizeLine("foo = -> 1")
    expect(tokens[0]).toEqual value: "foo ", scopes: ["source.taco", "meta.function.taco", "entity.name.function.taco"]

    {tokens} = grammar.tokenizeLine("foo bar")
    expect(tokens[0]).toEqual value: "foo ", scopes: ["source.taco", "entity.name.function.taco"]

    {tokens} = grammar.tokenizeLine("eat food for food in foods")
    expect(tokens[0]).toEqual value: "eat ", scopes: ["source.taco", "entity.name.function.taco"]
    expect(tokens[1]).toEqual value: "food ", scopes: ["source.taco"]
    expect(tokens[2]).toEqual value: "for", scopes: ["source.taco", "keyword.control.taco"]
    expect(tokens[3]).toEqual value: " food ", scopes: ["source.taco"]
    expect(tokens[4]).toEqual value: "in", scopes: ["source.taco", "keyword.control.taco"]
    expect(tokens[5]).toEqual value: " foods", scopes: ["source.taco"]

    {tokens} = grammar.tokenizeLine("foo @bar")
    expect(tokens[0]).toEqual value: "foo ", scopes: ["source.taco", "entity.name.function.taco"]
    expect(tokens[1]).toEqual value: "@bar", scopes: ["source.taco", "variable.other.readwrite.instance.taco"]

    {tokens} = grammar.tokenizeLine("foo baz, @bar")
    expect(tokens[0]).toEqual value: "foo ", scopes: ["source.taco", "entity.name.function.taco"]
    expect(tokens[1]).toEqual value: "baz", scopes: ["source.taco"]
    expect(tokens[3]).toEqual value: "@bar", scopes: ["source.taco", "variable.other.readwrite.instance.taco"]

  it "does not tokenize booleans as functions", ->
    {tokens} = grammar.tokenizeLine("false unless true")
    expect(tokens[0]).toEqual value: "false", scopes: ["source.taco", "constant.language.boolean.false.taco"]
    expect(tokens[2]).toEqual value: "unless", scopes: ["source.taco", "keyword.control.taco"]
    expect(tokens[4]).toEqual value: "true", scopes: ["source.taco", "constant.language.boolean.true.taco"]

    {tokens} = grammar.tokenizeLine("true if false")
    expect(tokens[0]).toEqual value: "true", scopes: ["source.taco", "constant.language.boolean.true.taco"]
    expect(tokens[2]).toEqual value: "if", scopes: ["source.taco", "keyword.control.taco"]
    expect(tokens[4]).toEqual value: "false", scopes: ["source.taco", "constant.language.boolean.false.taco"]
