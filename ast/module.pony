class Module
  let ast: AST
  let file: String
  let len: USize

  new create(ast': AST) ? =>
    ast = ast'
    let source: _Source = ast.source().apply()?
    let f_ptr = source.file
    file = recover val String.copy_cstring(f_ptr) end
    len = source.len

class _ModuleIter is Iterator[Module]
  var _module_ast: (AST | None)
  // corresponds to Source
  // add file field

  new ref create(package: Package box) =>
    _module_ast = package.ast.child()

  fun ref has_next(): Bool =>
    _module_ast isnt None

  fun ref next(): Module ? =>
    let module_ast = _module_ast as AST
    _module_ast = module_ast.sibling()
    Module.create(module_ast)?

