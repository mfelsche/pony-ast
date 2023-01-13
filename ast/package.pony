use @package_init[Bool](opt: _PassOpt)
use @package_init_lib[Bool](opt: _PassOpt, pony_installation: Pointer[U8] tag)
use @package_done[None](opt: _PassOpt)

class Package
  """
  Represents a pony package
  """
  let ast: AST
  let qualified_name: String val
  let path: String val

  new create(ast': AST) ? =>
    ast = ast'
    let package: _Package = ast.package().apply()?
    let q_name_ptr = package.qualified_name
    qualified_name = recover val String.copy_cstring(q_name_ptr) end
    let path_ptr = package.path
    path = recover val String.copy_cstring(path_ptr) end

  fun modules(): Iterator[Module] =>
    _ModuleIter.create(this)

class _PackageIter is Iterator[Package]
  var _package_ast: (AST | None)

  new ref create(program: Program box) =>
    _package_ast = program.ast.child()

  fun ref has_next(): Bool =>
    _package_ast isnt None

  fun ref next(): Package ? =>
    let package_ast = _package_ast as AST
    _package_ast = package_ast.sibling()
    Package.create(package_ast)?

struct _PackageSet
  """STUB"""

struct _PackageGroup
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
  let ast: NullablePointer[_AST] = ast.none()
  let dependencies: NullablePointer[_PackageSet] = dependencies.none()
  let group: NullablePointer[_PackageGroup] = group.none()
  let group_index: USize = 0
  let next_hygienic_id: USize = 0
  let low_index: USize = 0
  let allow_ffi: Bool = true
  let on_stack: Bool = true

