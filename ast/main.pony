use "lib:ponyc-standalone"

use @stringtab_init[None]()
use @stringtab_done[None]()
//use @pass_opt_init[None](options: NullablePointer[PassOptT])
use @program_create[_Program]()
use @program_free[None](program: _Program)
use @program_load[NullablePointer[_AST]](path: Pointer[U8] tag, opt: _PassOpt)

use @package_init[Bool](opt: _PassOpt)
use @package_init_lib[Bool](opt: _PassOpt, pony_installation: Pointer[U8] tag)
use @package_done[None](opt: _PassOpt)

use @printf[None](s: Pointer[U8] tag)

use "debug"

struct _Program

primitive VerbosityLevels
  fun quiet(): I32 => 0

  fun minimal(): I32 => 1

  fun info(): I32 => 2

  fun tool_info(): I32 => 3

  fun all(): I32 => 4

type VerbosityLevel is I32

actor Main
  new create(env: Env) =>
    try
      let path = env.args(1)?
      let line = env.args(2)?.usize()?
      let column = env.args(3)?.usize()?

      let pass_opt = _PassOpt.create()
      @pass_opt_init(pass_opt)
      pass_opt.verbosity = VerbosityLevels.quiet()
      pass_opt.limit = PassIds.expr()
      pass_opt.release = false
      try
        pass_opt.argv0 = env.args(0)?.cstring()
      end

      @codegen_pass_init(pass_opt)
      @package_init(pass_opt)

      // TODO: parse builtin before and keep it around, so we don't need to
      // process it over and over
      let program_ast = @program_load(path.cstring(), pass_opt)
      if program_ast.is_none() then
        @printf("Error loading Program\n".cstring())
        if not pass_opt.check.errors.is_none() then
          let errors = pass_opt.check.errors()?
          let num_errors = @errors_get_count(errors)
          if num_errors > 0 then
            @errors_print(errors)
          end
        end
      else
        let package = @ast_child(program_ast()?)()?
        // TODO: make relative to folder
        let ast_type = get_type_at("/home/mat/dev/pony/pony-ast/examples/main.pony", line, column, package)
        env.out.print("Type: " + ast_type.string())
        //@ast_print(program_ast()?, 80)
        @ast_free(program_ast()?)
      end

      @package_done(pass_opt)
      @codegen_pass_cleanup(pass_opt)
      @pass_opt_done(pass_opt)
    else
      @printf("Error loading the program\n".cstring())
      env.exitcode(1)
    end

  fun get_type_at(file: String, line: USize, column: USize, package: _AST): (String | None) =>
    let module_ptr = get_module(file, package)
    try
      let module: AST = AST(module_ptr()?)

      match get_ast_at(line, column, module)
      | let ast: AST =>
        Debug("FOUND " + TokenIds.string(ast.id()))
        get_ast_type(ast)
      | None => None
      end
    end

  fun get_ast_type(ast: AST): (String | None) =>
    """
    Handle some special cases of AST constructs
    for getting a type
    """
    try
      match ast.id()
      | TokenIds.tk_letref() | TokenIds.tk_varref() | TokenIds.tk_match_capture() =>
        let def: _AST = @ast_data[NullablePointer[_AST]](ast.raw)()?
        AST(def).ast_type_string()
      | TokenIds.tk_fletref() =>
        // e.g. x.b.method_call()
        //      ^^^-- this is a tk_fletref
        let lhs = ast.child() as AST
        let rhs = lhs.sibling() as AST
        Debug("FLETREF RHS: " + TokenIds.string(rhs.id()) + " POS: " + rhs.pos().string() + ": " + rhs.token_value().string())
        if (rhs.line() > lhs.line()) or ((rhs.line() == lhs.line()) and (rhs.pos() > lhs.pos())) then
          // chose lhs
          get_ast_type(lhs)
        else
          rhs.ast_type_string()
        end
      | TokenIds.tk_beref() =>
        "None val^"
      | TokenIds.tk_call() =>
        let parens = ast.child() as AST
        // immediate child is a funref, whose first child is the thing the
        // function is called on
        let lhs = (ast.child() as AST).child() as AST
        Debug("CALL LHS: " + TokenIds.string(lhs.id()))

        if (parens.line() > lhs.line()) or ((parens.line() == lhs.line()) and (parens.pos() > lhs.pos())) then
          // chose lhs
          get_ast_type(lhs)
        else
          // chose type of call -> return type
          ast.ast_type_string()
        end
      | TokenIds.tk_id() =>
        match ast.parent()
        | let parent: AST =>
          match parent.id()
          | TokenIds.tk_param() =>
            // if we get a TK_ID, check if it is the name of a TK_PARAM
            parent.ast_type_string()
          | TokenIds.tk_fun() | TokenIds.tk_be() | TokenIds.tk_new() =>
            parent(4)?.type_string()
          | TokenIds.tk_fletref() | TokenIds.tk_fvarref() | TokenIds.tk_let() | TokenIds.tk_var() =>
            parent.ast_type_string()
          end
        end
      | TokenIds.tk_none() =>
        try
          let parent = ast.parent() as AST
          match parent.id()
            // special case for ffi_call
            // when using an ffi_call without explicit return type
            // our search often returns TK_NONE from this optional node
            // report the type of the fficall in this case
          | TokenIds.tk_fficall() => parent.ast_type_string()
            // if we have an optional token on a fun definition
            // return the fun return type
          | TokenIds.tk_fun() | TokenIds.tk_be() | TokenIds.tk_new() =>
            parent(4)?.type_string()
          end
        end
      | TokenIds.tk_seq() | TokenIds.tk_params() =>
        // lets assume if we get a seq or params with the algorithm in `get_ast_at`
        // we almost always want to get the first element
        try
          (ast.child() as AST).ast_type_string()
        end
      else
        ast.ast_type_string()
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

  fun get_module(file: String, package: _AST): NullablePointer[_AST] =>
    Debug("trying to find module from: " + file)
    try
      var module_ptr = @ast_child(package)
      while not module_ptr.is_none() do
        let module: _AST = module_ptr()?
        let source = @ast_source(module)
        if not source.is_none() then
          let source_file = String.copy_cstring(source()?.file)
          Debug("checking: " +  source_file)
          if file == source_file then
            Debug("found module: " + file)
            return NullablePointer[_AST].create(module)
          end
        end
        module_ptr = @ast_sibling(module)
      end
      NullablePointer[_AST].none()
    else
      NullablePointer[_AST].none()
    end


