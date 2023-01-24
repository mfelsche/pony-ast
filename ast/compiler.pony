use "files"

primitive Compiler
  fun _init() =>
    @stringtab_init()

  fun _final() =>
    @stringtab_done()

  fun compile(env: Env, path: FilePath): (Program | Array[Error]) =>
    let pass_opt = _PassOpt.create()
    @pass_opt_init(pass_opt)
    pass_opt.verbosity = VerbosityLevels.quiet()
    pass_opt.limit = PassIds.expr()
    pass_opt.release = false
    try
      pass_opt.argv0 = env.args(0)?.cstring()
    end

    @codegen_pass_init(pass_opt)
    // this will load PONYPATH from env
    @package_init(pass_opt)

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
