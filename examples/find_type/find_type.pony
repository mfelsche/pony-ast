use "files"
use "cli"
use "../../ast"
use "debug"

actor Main
  new create(env: Env) =>
    let cs =
      try
        CommandSpec.leaf("find_type", "Find the type at a certain position in your pony program", [
        ], [
          ArgSpec.string("directory", "The program directory")
          ArgSpec.string("file", "The file to search for a type in")
          ArgSpec.u64("line", "The line in the source file, starts with 1")
          ArgSpec.u64("column", "The column on the given line, starts with 1")
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
    try
      let program_dir_str = cmd.arg("directory").string()
      if program_dir_str.size() == 0 then
        env.err.print("Missing or invalid directory")
        error
      end
      let program_dir = FilePath.create(FileAuth(env.root), program_dir_str)
      let file = cmd.arg("file").string()
      if file.size() == 0 then
        env.err.print("Missing or invalid file")
        error
      end
      let line = cmd.arg("line").u64()
      if line == 0 then
        env.err.print("Missing or invalid line")
        error
      end
      let column = cmd.arg("column").u64()
      if column == 0 then
        env.err.print("Missing or invalid column")
        error
      end
      find_type(env, program_dir, file, line.usize(), column.usize())
    else
      env.exitcode(1)
    end

  be find_type(
    env: Env,
    program_dir: FilePath,
    file: String,
    line: USize,
    column: USize)
  =>
    try
      match Compiler.compile(env, program_dir)
      | let program: Program =>
        env.out.print("OK")
        let t = get_type_at(file, line, column, program.package() as Package) as String
        env.out.print("Type: " + t)
      | let errors: Array[Error] =>
        env.out.print("ERROR")
      end
    else
      env.exitcode(1)
    end

  fun get_type_at(file: String, line: USize, column: USize, package: Package): (String | None) =>
    try
      let module = get_module(file, package) as Module

      match get_ast_at(line, column, module.ast)
      | let ast: AST =>
        Debug("FOUND " + TokenIds.string(ast.id()))
        Types.get_ast_type(ast)
      | None => None
      end
    end


  fun get_ast_at(line: USize, column: USize, ast: AST): (AST | None) =>
    try
      var child: AST = ast.child() as AST
      while true do
        let child_pos = child.pos()
        Debug("Checking child " + TokenIds.string(child.id()) + " at line: " + child.line().string() + " col: " + child_pos.string())
        if child.line() == line then
          Debug("line " + line.string() + " found")
          Debug("pos: " + child_pos.string() + " column: " + column.string() + " == " + (child_pos == column).string() + ", > " + (child_pos > column).string())

          // check the position of the last child
          // if it is beyond our intended column, one of the children of this
          // node is ours
          try
            let last_child = child.last_child()
            let last_child_pos = (last_child as AST).pos()
            Debug("Last child pos: " + last_child_pos.string())
            if (last_child_pos == column) and (last_child_pos > child_pos) then
              return child.last_child()
            elseif (child_pos < column) and (column < last_child_pos) then
              // our thingy is somewhere in here
              Debug("Descend into " + TokenIds.string(child.id()))
              // it must be somewhere in there, no need to iterate further
              // also return if it is None, it is here or nowhere
              return get_ast_at(line, column, child)
            end
          end

          // we can get the length of ids and strings
          // use it to correctly match the token
          match child.token_value()
          | let s: String =>
            // strings have at least 1 trailing quote
            let ast_end = child.pos() + s.size() + if child.id() == TokenIds.tk_string() then 1 else 0 end
            if (child.pos() <= column) and (column <= ast_end) then
              return child
            end
          | None =>
            if child.pos() >= column then
              if (child.pos() == column) then
                return child
              elseif child.infix_node() then
                Debug("INFIX NODE " + TokenIds.string(child.id()))
                // infix nodes might have some lhs child that is closer to the
                // actual position, so go inside and check
                match get_ast_at(line, column, child)
                | let in_child: AST => return in_child
                | None => return child
                end
              else
                // we are past our desired columns
                // return the previous or the parent node
                let prev = child.prev()
                if prev is None then
                  return ast
                else
                  return prev
                end
              end
            end
          end


        end
        // recurse to childs children
        match get_ast_at(line, column, child)
        | let found: AST => return found
        end
        child = child.sibling() as AST
      end
    end

  fun get_module(file: String, package: Package): (Module | None) =>
    Debug("trying to find module from: " + file)
    for module in package.modules() do
      Debug("checking: " +  module.file)
      if module.file == file then
        Debug("found module: " + file)
        return module
      end
    end

