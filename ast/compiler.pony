use "files"
use "cli"

primitive Compiler
  """
  Main entry point for obtaining a `Program` that wraps up the Pony `AST`
  produced by the underlying libponyc.

  This "Compiler" here is calling the libponyc function `program_load`
  and configures it to compile up to the `expr` pass with `quiet` verbosity.
  So this is not producing any Pony binary, ASM or LLVM IR, but it is giving you
  some convenient wrapper around the libponyc `ast_t` that represents the Pony program.
  """
  fun _init() =>
    @stringtab_init()

  fun _final() =>
    @stringtab_done()

  fun compile(
    env: Env,
    path: FilePath,
    package_search_paths: ReadSeq[String val] box = [])
  : (Program | Array[Error])
  =>
    """
    Compile the pony source code at the given `path` with the paths in `package_search_paths`
    to look for "used" packages.

    This function will also load the path in the `PONYPATH` environment variable,
    if present.
    """
    let pass_opt = _PassOpt.create()
    @pass_opt_init(pass_opt)
    pass_opt.verbosity = VerbosityLevels.quiet()
    pass_opt.limit = PassIds.expr()
    pass_opt.release = false
    try
      pass_opt.argv0 = env.args(0)?.cstring()
    end

    @codegen_pass_init(pass_opt)
    let env_vars = EnvVars(env.vars)
    try
      let pony_path = env_vars("PONYPATH")?
      @package_add_paths(pony_path.cstring(), pass_opt)
    end
    // avoid calling package_init
    for search_path in package_search_paths.values() do
      @package_add_paths(search_path.cstring(), pass_opt)
    end

    // TODO: parse builtin before and keep it around, so we don't need to
    // process it over and over
    let program_ast = @program_load(path.path.cstring(), pass_opt)
    let res =
      if program_ast.is_null() then
        try
          let errors = pass_opt.check.errors()?
          errors.extract() // extracts an array of errors
        else
          [
            Error.message("Compilation failed but libponyc produced no error messages.")
          ]
        end
      else
        Program.create(AST(program_ast))
      end

    @package_done(pass_opt)
    @codegen_pass_cleanup(pass_opt)
    @pass_opt_done(pass_opt)
    res
