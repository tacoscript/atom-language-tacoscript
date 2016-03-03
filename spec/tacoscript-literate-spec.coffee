describe "TacoScript (Literate) grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-tacoscript")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.litaco")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.litaco"
