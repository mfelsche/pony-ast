use "files"

primitive Compiler
  fun compile(env: Env, path: FilePath): (Program | Array[Error]) =>
    @stringtab_init()
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
      if program_ast.is_none() then
        try
          let errors = pass_opt.check.errors()?
          errors.extract() // extracts an array of errors
        else
          Array[Error].create(0)
        end
      else
        try
          Program.create(AST(program_ast()?))
        else
          Array[Error].create(0)
        end
        //let package = @ast_child(program_ast()?)()?

        //let ast_type = get_type_at("/home/mat/dev/pony/pony-ast/examples/main.pony", line, column, package)
        //env.out.print("Type: " + ast_type.string())
        //@ast_print(program_ast()?, 80)
        //@ast_free(program_ast()?)
      end

    @package_done(pass_opt)
    @codegen_pass_cleanup(pass_opt)
    @pass_opt_done(pass_opt)
    @stringtab_done()
    res
