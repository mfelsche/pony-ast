use "lib:ponyc-standalone" if posix or osx
// windows is not supported yet
use "lib:c++" if osx
use "files"


use @program_create[_Program]()
use @program_free[None](program: _Program)
use @program_load[Pointer[_AST]](path: Pointer[U8] tag, opt: _PassOpt)

use @printf[None](s: Pointer[U8] tag, ...)

struct _Program

primitive VerbosityLevels
  fun quiet(): I32 => 0

  fun minimal(): I32 => 1

  fun info(): I32 => 2

  fun tool_info(): I32 => 3

  fun all(): I32 => 4

type VerbosityLevel is I32

class Program
  let ast: AST

  new create(ast': AST) =>
    ast = ast'

  fun package(): (Package | None) =>
    """
    The package representing the source directory
    """
    match ast.child()
    | let p_ast: AST =>
      try
        Package.create(this, p_ast)?
      end
    end

  fun packages(): Iterator[Package] =>
    """
    Source directory is always the first package.
    Second is builtin.
    The rest is still unknown to me.
    """
    _PackageIter.create(this)

  fun apply(package': String): Package ? =>
    let package_ast = ast.find_in_scope(package') as AST
    Package.create(this, package_ast)?

  fun _final() =>
    if not ast.raw.is_null() then
      @ast_free(ast.raw)
    end

