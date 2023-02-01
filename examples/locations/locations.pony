use "../../ast"
use "cli"
use "files"
use "term"

actor Main
  new create(env: Env) =>
    let cs =
      try
        CommandSpec.leaf(
          "locations",
          "Debug the reported locations for each AST node",
          [
            OptionSpec.string_seq("paths", "paths to add to the package search path" where short' = 'p')
          ],
          [
            ArgSpec.string("directory", "The program directory")
          ]
        )? .> add_help()?
      else
        env.exitcode(-1)  // some kind of coding error
        return
      end
    let cmd =
      match CommandParser(cs).parse(env.args, env.vars)
      | let c: Command => c
      | let ch: CommandHelp =>
          ch.print_help(env.out)
          env.exitcode(0)
          return
      | let se: SyntaxError =>
          env.out.print(se.string())
          env.exitcode(1)
          return
      end
    var dir = cmd.arg("directory").string()
    if dir.size() == 0 then
      dir = "."
    end
    // extract PONYPATH
    let pony_path = PonyPath(env)
    // extract search paths from cli
    let cli_search_paths = cmd.option("paths").string_seq()

    let search_paths =
      recover val
        let tmp = Array[String val](cli_search_paths.size() + 1)
        match pony_path
        | let pp_str: String val =>
          tmp.push(pp_str)
        end
        tmp.append(cli_search_paths)
        tmp
      end

    let path = FilePath(FileAuth(env.root), dir)
    match Compiler.compile(path, search_paths)
    | let program: Program =>
      try
        (program.package() as Package ref).ast.visit(_ASTLocationVisitor(env.out))
      else
        env.err.print("No package in our program???")
      end
    | let errors: Array[Error] =>
      env.out.print("Found " + ANSI.bold(true) + ANSI.red() + errors.size().string() + ANSI.reset() + " Errors:")
      for err in errors.values() do
        match err.file
        | let file: String val =>
          env.out.print(
            "[ " +
            file +
            ":" +
            err.line.string() +
            ":" +
            err.pos.string() +
            " ] " +
            ANSI.bold(true) +
            err.msg +
            ANSI.reset()
          )
        | None =>
          env.out.print(
            ANSI.bold(true) +
            err.msg +
            ANSI.reset()
          )
        end
      end
    end

class _ASTLocationVisitor is ASTVisitor
  let _out: OutStream
  var _source: String val = ""

  new create(out: OutStream) =>
    _out = out

  fun ref visit(ast: AST box): VisitResult =>
    try
      let a_s = ast.source_file()
      if _source.size() == 0 then
        if a_s isnt None then
          _source = a_s as String val
        end
      end
      var num_parents: USize = 0
      var parent = ast.parent()
      while parent isnt None do
        num_parents = num_parents + 1
        parent = (parent as AST box).parent()
        _out.write(" ")
      end
      let token_str =
        match ast.id()
        | TokenIds.tk_string() =>
          "\"" + (ast.token_value() as String val) + "\""
        | TokenIds.tk_id() => ast.token_value() as String val
        else
          TokenIds.string(ast.id())
        end

      var source: String val = ""
      if (_source.size() > 0) and (a_s isnt None) then
        let a_ss = (a_s as String val)

        if a_ss != _source then
          source = a_ss
        end
      end
      _out.print(token_str + " @ " + ast.line().string() + ":" + ast.pos().string() + " " + source)
      Continue
    else
      Stop
    end
