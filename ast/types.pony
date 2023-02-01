use "debug"

primitive Types
  fun get_ast_type(ast: AST box): (String | None) =>
    """
    Handle some special cases of AST constructs
    for getting a type
    """
    try
      match ast.id()
      | TokenIds.tk_letref() | TokenIds.tk_varref() | TokenIds.tk_match_capture() =>
        let def: Pointer[_AST] = @ast_data[Pointer[_AST]](ast.raw)
        if not def.is_null() then
          AST(def).ast_type_string()
        end
      | TokenIds.tk_fletref() =>
        // e.g. x.b.method_call()
        //      ^^^-- this is a tk_fletref
        let lhs = ast.child() as AST
        let rhs = lhs.sibling() as AST
        Debug("FLETREF RHS: " + rhs.debug())
        if (rhs.line() > lhs.line()) or ((rhs.line() == lhs.line()) and (rhs.pos() > lhs.pos())) then
          // chose lhs
          get_ast_type(lhs)
        else
          rhs.ast_type_string()
        end
      | TokenIds.tk_newref() =>
        let funtype = ast.ast_type() as AST
        funtype(3)?.type_string()
      | TokenIds.tk_beref() =>
        // hard-coding to implicit return type of a behavior
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
          Debug("TK_ID parent: " + parent.debug())
          match parent.id()
          | TokenIds.tk_param() =>
            // if we get a TK_ID, check if it is the name of a TK_PARAM
            parent.ast_type_string()
          | TokenIds.tk_fun() | TokenIds.tk_be() | TokenIds.tk_new() =>
            // it is a function/behavior/constructor name
            parent(4)?.type_string()
          | TokenIds.tk_newref() | TokenIds.tk_funref() | TokenIds.tk_beref() | TokenIds.tk_newberef() =>
            let funtype = parent.ast_type() as AST
            funtype(3)?.type_string()
          | TokenIds.tk_typeref() =>
            parent.ast_type_string()
          | TokenIds.tk_nominal() =>
            // it is a type
            parent.type_string()
          | TokenIds.tk_let() | TokenIds.tk_fletref()  // let fields
          | TokenIds.tk_fvar() | TokenIds.tk_fvarref() // var fields
          | TokenIds.tk_embed()                        // embed fields
          | TokenIds.tk_var() =>
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
          | TokenIds.tk_nominal() =>
            parent.type_string()
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

