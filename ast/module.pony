class Module
  let ast: AST
  let file: String
  let len: USize

  // this one is just kept around so the underlying AST is not lost
  // it is reaped when the Program is collected by GC
  let _program: Program box

  new create(program: Program box, ast': AST) ? =>
    _program = program
    ast = ast'
    let source: _Source = ast.source().apply()?
    let f_ptr = source.file
    file = recover val String.copy_cstring(f_ptr) end
    len = source.len

class _ModuleIter is Iterator[Module]
  var _module_ast: (AST | None)
  let _program: Program box

  new ref create(program: Program box, package: Package box) =>
    _program = program
    _module_ast = package.ast.child()

  fun ref has_next(): Bool =>
    _module_ast isnt None

  fun ref next(): Module ? =>
    let module_ast = _module_ast as AST
    _module_ast = module_ast.sibling()
    Module.create(_program, module_ast)?

