use "../../ast"
use "term"
use "cli"
use "files"

actor Main
  new create(env: Env) =>
    let cs =
      try
        CommandSpec.leaf("compile", "Compile a pony program and spit out errors if any", [
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
    match Compiler.compile(env, FilePath(FileAuth(env.root), dir))
    | let p: Program =>
      env.out.print("OK")

    | let errs: Array[Error] =>
      env.err.print("Found " + ANSI.bold(true) + ANSI.red() + errs.size().string() + ANSI.reset() + " Errors:")
      for err in errs.values() do
        env.err.print("[ " + err.file + ":" + err.line.string() + ":" + err.pos.string() + " ] " + ANSI.bold(true) + err.msg + ANSI.reset())
      end
    end

