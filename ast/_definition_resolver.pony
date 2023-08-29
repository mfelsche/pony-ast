use "debug"

primitive DefinitionResolver
  fun _data_ast(ast: AST box): (AST | None) =>
    let ptr = ast.data[_AST]()
      if ptr.is_null() then
        None
      else
        AST(ptr)
      end  
  
  fun resolve(ast: AST box): (AST | None) =>
    match ast.id()
    // locals
    | TokenIds.tk_varref() | TokenIds.tk_letref() => _data_ast(ast)
    // parameters
    | TokenIds.tk_paramref() => _data_ast(ast)
    // functions, behaviours and constructors
    // these don't have a reference to the definition
    // in their data field - why though?
    | TokenIds.tk_funref() | TokenIds.tk_beref() 
    | TokenIds.tk_newref() | TokenIds.tk_newberef()
    | TokenIds.tk_funchain() | TokenIds.tk_bechain() =>
      try
        let receiver = ast.child() as AST
        Debug("RECEIVER " + receiver.debug() )
        let method = receiver.sibling() as AST
        let method_name = method.token_value() as String
        let receiver_type = receiver.ast_type() as AST    
        let receiver_def = _data_ast(receiver_type) as AST
        Debug("searching inside definition: " + receiver_def.debug())
        // TODO: more efficient searching for methods etc. 
        // e.g. we don't need to visit the whole tree, but we know where these should be
        let found = receiver_def.find_node({
          (ast: AST box): Bool =>
            match ast.id()
            | TokenIds.tk_fun() | TokenIds.tk_new() | TokenIds.tk_be() =>
              try
                let name = ast(1)?
                name.token_value() as String == method_name
              else
                false
              end
            else
              false
            end
        }) as AST box
        Debug("FOUND: " + found.debug())
        // horrible hack to turn an AST box into an AST ref, yolo
        let sibling_idx = found.sibling_idx()
        let parent = found.parent() as AST
        let res = parent(sibling_idx)?
        Debug("FOUND res: " + res.debug())
        res
      end
    // fields
    | TokenIds.tk_fvarref() | TokenIds.tk_fletref() | TokenIds.tk_embedref() =>
      _data_ast(ast)
    | TokenIds.tk_typeref() => _data_ast(ast)
    // TODO: | TokenIds.tk_typeparamref()
    // TODO: | TokenIds.tk_tupleelemref()
    // TODO: | TokenIds.tk_packageref()
    else
      None
    end
