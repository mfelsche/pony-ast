use "../../ast"
use "term"
use "cli"
use "files"

actor CompilerActor

  var package: (Package | None) = None

  be compile(env: Env, path: FilePath, search_paths: ReadSeq[String] val = []) =>
    env.out.print("compiling...")
    match Compiler.compile(env, path, search_paths)
    | let p: Program =>
      package = try
        p.package() as Package
      end
      env.out.print("OK")

    | let errs: Array[Error] =>
      env.err.print("Found " + ANSI.bold(true) + ANSI.red() + errs.size().string() + ANSI.reset() + " Errors:")
      for err in errs.values() do
        match err.file
        | let file: String val =>
          env.err.print(
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
          env.err.print(
            ANSI.bold(true) +
            err.msg +
            ANSI.reset()
          )
        end
      end
    end

actor Main
  new create(env: Env) =>
    let cs =
      try
        CommandSpec.leaf(
          "compile",
          "Compile a pony program and spit out errors if any",
          [
            OptionSpec.string_seq("paths", "paths to add to the package search path" where short' = 'p')
          ], [
          ArgSpec.string("directory", "The program directory")
        ])? .> add_help()?
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

    let search_paths = cmd.option("paths").string_seq()
    var rounds: USize = 4
    let path = FilePath(FileAuth(env.root), dir)
    let ca = CompilerActor
    while rounds > 0 do
      ca.compile(env, path, search_paths)

      rounds = rounds - 1
    end

