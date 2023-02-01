use "debug"
use @package_init[Bool](opt: _PassOpt)
use @package_add_paths[None](paths: Pointer[U8] tag, opy: _PassOpt)
use @package_init_lib[Bool](opt: _PassOpt, pony_installation: Pointer[U8] tag)
use @package_done[None](opt: _PassOpt)

class Package
  """
  Represents a pony package
  """
  let ast: AST
  let qualified_name: String val
  let path: String val

  // this one is just kept around so the underlying AST is not lost
  // it is reaped when the Program is collected by GC
  let _program: Program box

  new create(program: Program box, ast': AST) ? =>
    _program = program
    ast = ast'
    let package: _Package = ast.package().apply()?
    let q_name_ptr = package.qualified_name
    qualified_name = recover val String.copy_cstring(q_name_ptr) end
    let path_ptr = package.path
    path = recover val String.copy_cstring(path_ptr) end

  fun module(): (Module | None) =>
    """
    Returns the first Module in this Package
    """
    match ast.child()
    | let m_ast: AST =>
      try
        Module.create(this._program, m_ast)?
      end
    end

  fun modules(): Iterator[Module] =>
    _ModuleIter.create(_program, this)

  fun find_module(file: String): (Module | None) =>
    """
    Find a module in this package by package directory path
    """
    Debug("trying to find module from: " + file)
    for mod in modules() do
      Debug("checking: " +  mod.file)
      if mod.file == file then
        Debug("found module: " + file)
        return mod
      end
    end

class _PackageIter is Iterator[Package]
  var _package_ast: (AST | None)
  let _program: Program box

  new ref create(program: Program box) =>
    _package_ast = program.ast.child()
    _program = program

  fun ref has_next(): Bool =>
    _package_ast isnt None

  fun ref next(): Package ? =>
    let package_ast = _package_ast as AST
    _package_ast = package_ast.sibling()
    Package.create(_program, package_ast)?

primitive _PackageSet
  """STUB"""

primitive _PackageGroup
  """STUB"""

struct _Package
  let path: Pointer[U8] val = path.create()
    """absolute path"""
  let qualified_name: Pointer[U8] val = qualified_name.create()
    """
    For pretty printing, eg "builtin"
    """
  let id: Pointer[U8] val = id.create()
    """hygienic identifier"""
  let filename: Pointer[U8] val = filename.create()
    """directory name"""
  let symbol: Pointer[U8] val = symbol.create()
    """Wart to use for symbol names"""
  let ast: Pointer[_AST] = ast.create()
  let dependencies: Pointer[_PackageSet] = dependencies.create()
  let group: Pointer[_PackageGroup] = group.create()
  let group_index: USize = 0
  let next_hygienic_id: USize = 0
  let low_index: USize = 0
  let allow_ffi: Bool = true
  let on_stack: Bool = true

