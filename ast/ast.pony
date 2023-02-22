use "debug"
use "collections"

use @ast_blank[_AST](id: TokenId)

// allocate a new
use @ast_new[Pointer[_AST]](t: _Token, id: TokenId)
// generate (allocate) an AST node for the given token
use @ast_token[Pointer[_AST]](t: _Token)
use @ast_id[TokenId](ast: Pointer[_AST] box)
use @ast_source[NullablePointer[_Source]](ast: Pointer[_AST] box)
use @ast_line[USize](ast: Pointer[_AST] box)
use @ast_pos[USize](ast: Pointer[_AST] box)

use @ast_free[None](ast: Pointer[_AST] box)
// only free the AST if it has no parent
use @ast_free_unattached[None](ast: Pointer[_AST])
// only for string or id
use @ast_name[Pointer[U8] val](ast: Pointer[_AST] box)
use @ast_name_len[USize](ast: Pointer[_AST] box)
use @ast_nice_name[Pointer[U8] val](ast: Pointer[_AST] box)
use @ast_type[Pointer[_AST]](ast: Pointer[_AST] box)
use @ast_print_type[Pointer[U8] val](ast: Pointer[_AST] box)
use @ast_print[Pointer[U8] val](ast: Pointer[_AST] box, width: USize)
// mark the given AST as having its own scope
//use @ast_scope[None](ast: _AST ref)

use @ast_parent[Pointer[_AST]](ast: Pointer[_AST] box)
use @ast_child[Pointer[_AST]](ast: Pointer[_AST] box)
use @ast_childlast[Pointer[_AST]](ast: Pointer[_AST] box)
use @ast_sibling[Pointer[_AST]](ast: Pointer[_AST] box)
use @ast_previous[Pointer[_AST]](ast: Pointer[_AST] box)
use @ast_childidx[Pointer[_AST]](ast: Pointer[_AST] box, idx: USize)
use @ast_childcount[USize](ast: Pointer[_AST] box)
use @ast_data[Pointer[None]](ast: Pointer[_AST] box)
use @ast_index[USize](ast: Pointer[_AST] box)

use @ast_get[_AST](ast: Pointer[_AST] box, name: Pointer[U8] tag, status: NullablePointer[SymStatus])


struct _Symtab
  """
  stupid stub
  """

struct SymStatus
  var status: I32 = SymStati.none()

primitive SymStati
  fun none(): I32 => 0
  fun nocase(): I32 => 1
  fun defined(): I32 => 3
  fun undefined(): I32 => 4
  fun consumed(): I32 => 5
  fun consumed_same_expr(): I32 => 6
  fun ffidecl(): I32 => 7
  fun err(): I32 => 8

primitive _AST

class ref AST
  let raw: Pointer[_AST]

  new ref create(ast': Pointer[_AST]) =>
    raw = ast'

  fun box id(): TokenId =>
    @ast_id(raw)

  fun sibling_idx(): USize =>
    """
    number of previous siblings.
    """
    @ast_index(raw)

  fun box line(): USize =>
    @ast_line(raw)

  fun box pos(): USize =>
    @ast_pos(raw)

  fun box sibling(): (AST | None) =>
    let sibl = @ast_sibling(raw)
    if sibl.is_null() then
      None
    else
      AST(sibl)
    end

  fun box prev(): (AST | None) =>
    let p = @ast_previous(raw)
    if p.is_null() then
      None
    else
      AST(p)
    end

  fun box first_sibling(): (AST | None) =>
    """
    Could return this node
    """
    try
      (parent() as AST).child()
    end

  fun box child(): ( AST | None ) =>
    let c = @ast_child(raw)
    if c.is_null() then
      None
    else
      AST(c)
    end

  fun box last_child(): (AST | None ) =>
    let lc = @ast_childlast(raw)
    if lc.is_null() then
      None
    else
      AST(lc)
    end

  fun box apply(child_idx: USize): AST ? =>
    let ci = @ast_childidx(raw, child_idx)
    if ci.is_null() then
      error
    else
      AST(ci)
    end

  fun box parent(): (AST | None) =>
    let p = @ast_parent(raw)
    if p.is_null() then
      None
    else
      AST(p)
    end

  fun box num_parents(): USize =>
    var parents = USize(0)
    var p: (AST | None) = parent()
    while p isnt None do
      parents = parents + 1
      try
        p = (p as AST).parent()
      else
        break
      end
    end
    parents

  fun box token_value(): (String | None) =>
    """
    only works for TK_ID and TK_STRING
    uses @ast_name internally
    """
    if (id() == TokenIds.tk_id()) or (id() == TokenIds.tk_string()) then
      let ptr = @ast_name(raw)
      let len = @ast_name_len(raw)
      recover val String.copy_cpointer(ptr, len) end
    end

  fun box children(): Iterator[AST] =>
    // see ponyc/src/libponyc/ast/parser.c for the REORDER instructions
    match id()
    | TokenIds.tk_actor() | TokenIds.tk_class() | TokenIds.tk_struct() | TokenIds.tk_primitive()
    | TokenIds.tk_interface() | TokenIds.tk_trait() | TokenIds.tk_type() =>
      _ASTReorderedChildIter(this, [5; 2; 0; 1; 3; 6; 4])
    | TokenIds.tk_fun() | TokenIds.tk_new() | TokenIds.tk_be() =>
      _ASTReorderedChildIter(this, [0; 1; 2; 3; 4; 5; 7; 6])
    | TokenIds.tk_ifdef() =>
      _ASTReorderedChildIter(this, [0; 3; 1; 2])
    else
      _ASTChildIter(this)
    end

  fun box num_children(): USize =>
    @ast_childcount(raw)

  fun box is_leaf(): Bool =>
    """
    Returns `true` for AST nodes that don't have children.
    """
    @ast_child(raw).is_null()

  fun box source(): NullablePointer[_Source] =>
    """
    The source struct for this AST.
    Will only return a non-NULL pointer
    if this AST represents a module
    """
    @ast_source(raw)

  fun box source_file(): (String val | None) =>
    """
    Returns the absolute path of the AST node as string
    or None if the AST has no source_file attached.
    """
    try
      let ptr = source()()?.file
      recover val String.copy_cstring(ptr) end
    end

  fun box source_contents(): (String box | None) =>
    try
      let s = source()()?
      String.from_cpointer(s.m, s.len)
    end

  fun box package(): NullablePointer[_Package] =>
    """
    The package struct for this AST.
    Will only return a non-NULL pointer
    if this AST represents a package
    """
    @ast_data[NullablePointer[_Package]](raw)

  fun ast_type(): (AST | None) =>
    let t = @ast_type(raw)
    if t.is_null() then
      None
    else
      AST(t)
    end

  fun ast_type_string(): (String | None) =>
    """
    Get the type from this AST node and convert it to a String.
    Return `None` if the node has no type.
    """
    try
      let type_ast = ast_type() as AST
      let type_str_ptr = @ast_print_type(type_ast.raw)
      recover val String.copy_cstring(type_str_ptr) end
    end

  fun box type_string(): (String | None) =>
    """
    Prints this AST node representing a type. e.g. obtained with `ast_type()`
    """
    let type_str_ptr = @ast_print_type(raw)
    recover val String.copy_cstring(type_str_ptr) end

  fun box infix_node(): Bool =>
    """
    at infix nodes children can actually come before the actual AST node
    in the source
    """
    match id()
    | TokenIds.tk_uniontype()
    | TokenIds.tk_isecttype()
    | TokenIds.tk_tupletype()
    | TokenIds.tk_arrow()
    | TokenIds.tk_tuple()
    | TokenIds.tk_dot()
    | TokenIds.tk_funref()  // function call
    | TokenIds.tk_beref()  // behavior call
    | TokenIds.tk_newref() // constructor call
    | TokenIds.tk_fletref() // field access `a.b`
    | TokenIds.tk_tilde()
    | TokenIds.tk_chain()
    | TokenIds.tk_qualify()
    | TokenIds.tk_call()
    | TokenIds.tk_as()
    | TokenIds.tk_is()
    | TokenIds.tk_isnt()
    | TokenIds.tk_assign()
    => true
    else
      false
    end

  fun find_node(
    predicate: {(AST box): Bool},
    stop_if: {(AST box): Bool} = {(ast: AST box): Bool => false})
  : (AST box | None)
  =>
    """
    Find the first node in this AST that satisfies the given `predicate`.
    Stop searching further, once the `stop_if` predicate returns true.
    """
    let visitor = _ASTFindNodeVisitor(predicate, stop_if)
    visit(visitor)
    visitor.node()

  fun debug(with_source_file: Bool = false): String val =>
    let value =
      match token_value()
      | let s: String val =>
        " " + match id()
        | TokenIds.tk_string() => "\"" + s + "\""
        else
          s
        end
      | None => ""
      end
    let source_file' =
      if with_source_file then
        match source_file()
        | let sf: String val => " " + sf
        else
          ""
        end
      else
        ""
      end
    TokenIds.string(id()) + value + " @ " + line().string() + ":" + pos().string() + source_file'

  fun visit(visitor: ASTVisitor ref): VisitResult =>
    """
    visit all the child nodes of this node, not this node itself
    """
    let source' = source_file()
    // skip nodes not being set i.e. TK_NONE
    let filter_none: Bool =
      match id()
      // these nodes have some optional ast fields that just confuse the hell
      // out of us
      | TokenIds.tk_call() | TokenIds.tk_typeref() | TokenIds.tk_use()
      | TokenIds.tk_actor() | TokenIds.tk_class() | TokenIds.tk_struct()  // entities
      | TokenIds.tk_trait() | TokenIds.tk_interface() | TokenIds.tk_type() // entities
      | TokenIds.tk_new() | TokenIds.tk_fun() | TokenIds.tk_be() // method constructs
      | TokenIds.tk_fvar() | TokenIds.tk_flet() | TokenIds.tk_embed() // fields
      | TokenIds.tk_nominal() // types
      | TokenIds.tk_param()
      => true
      else
        false
      end
    // regular iteration through all the children
    for child' in children() do
      if child'._from_same_source(source') then
        if (not filter_none) or (child'.id() != TokenIds.tk_none()) then
          Debug("Visiting: " + child'.debug(true))
          if visitor.visit(child') is Stop then
            return Stop
          end

          if child'.visit(visitor) is Stop then
            return Stop
          end

          if visitor.leave(child') is Stop then
            return Stop
          end
        end
      end
    end
    Continue

  fun _from_same_source(source': (String val | None)): Bool =>
    match (source', this.source_file())
    | (let s1: String val, let s2: String val) =>
      s1 == s2
    else
      true
    end

  fun is_abstract(): Bool =>
    """
    Returns true if this `AST` node does not directly correspond to some
    characters in the source code.
    """
    match id()
    | TokenIds.tk_none()
    | TokenIds.tk_program()
    | TokenIds.tk_package()
    | TokenIds.tk_module()
    | TokenIds.tk_members()
    //| TokenIds.tk_fvar() // points to the var keyword
    //| TokenIds.tk_flet() // points to the let keyword
    | TokenIds.tk_dontcare()
    | TokenIds.tk_ffidecl()
    | TokenIds.tk_fficall()
    | TokenIds.tk_provides()
    // the pipe symbol in types
    //| TokenIds.tk_uniontype()
    // the ampersand symbol in types
    //| TokenIds.tk_isecttype()
    // the opening paren
    //| TokenIds.tk_tupletype()
    | TokenIds.tk_nominal()
    | TokenIds.tk_thistype()
    | TokenIds.tk_funtype()
    | TokenIds.tk_lambdatype()
    | TokenIds.tk_barelambdatype()
    | TokenIds.tk_dontcaretype()
    | TokenIds.tk_infertype()
    | TokenIds.tk_errortype()
    | TokenIds.tk_literal()
    | TokenIds.tk_literalbranch()
    | TokenIds.tk_operatorliteral()
    | TokenIds.tk_typeparams()
    | TokenIds.tk_typeparam()
    | TokenIds.tk_valueformalparam()
    | TokenIds.tk_params()
    | TokenIds.tk_param()
    | TokenIds.tk_typeargs()
    | TokenIds.tk_valueformalarg()
    | TokenIds.tk_positionalargs()
    | TokenIds.tk_namedargs()
    | TokenIds.tk_namedarg()
    | TokenIds.tk_updatearg()
    | TokenIds.tk_lambdacaptures()
    | TokenIds.tk_lambdacapture()
    | TokenIds.tk_lambda()
    | TokenIds.tk_barelambda()
    | TokenIds.tk_seq()
    | TokenIds.tk_qualify()
    //| TokenIds.tk_call()
    | TokenIds.tk_tuple()
    | TokenIds.tk_array()
    | TokenIds.tk_cases()
    | TokenIds.tk_case()
    | TokenIds.tk_try_no_check()
    | TokenIds.tk_reference()
    | TokenIds.tk_packageref()
    | TokenIds.tk_typeref()
    | TokenIds.tk_typeparamref()
    // those correspond to the member access dot
    //| TokenIds.tk_newref()
    //| TokenIds.tk_newberef()
    //| TokenIds.tk_beref()
    //| TokenIds.tk_funref()
    // those correspond to the member access dot
    //| TokenIds.tk_fvarref()
    //| TokenIds.tk_fletref()
    //| TokenIds.tk_tupleelemref()
    //| TokenIds.tk_embedref()
    | TokenIds.tk_varref()
    | TokenIds.tk_letref()
    | TokenIds.tk_paramref()
    | TokenIds.tk_dontcareref()
    // those take the place of the symbols
    //| TokenIds.tk_newapp()
    //| TokenIds.tk_beapp()
    //| TokenIds.tk_funapp()
    //| TokenIds.tk_bechain()
    //| TokenIds.tk_funchain()
    | TokenIds.tk_annotation()
    | TokenIds.tk_disposing_block()
    | TokenIds.tk_newline() => true
    else
      false
    end


  fun end_pos(): ((USize, USize) | None) =>
    """
    Return the position of the last character of the given AST node.
      
    For some nodes we know the actual size, so we can provide its exact end position.
    """
    let l = line()
    let col = pos()
    try
      match id()
      // symbols
      // 3 character symbols
      | TokenIds.tk_ellipsis() | TokenIds.tk_lshift_tilde() | TokenIds.tk_rshift_tilde()
      | TokenIds.tk_eq_tilde() | TokenIds.tk_ne_tilde() | TokenIds.tk_le_tilde() | TokenIds.tk_ge_tilde()
      | TokenIds.tk_lt_tilde() | TokenIds.tk_gt_tilde()
      | TokenIds.tk_mod_tilde()
      => (l, col + 2)
      // 2 character symbols
      | TokenIds.tk_arrow() | TokenIds.tk_dblarrow()
      | TokenIds.tk_plus_tilde() | TokenIds.tk_minus_tilde()
      | TokenIds.tk_multiply_tilde() | TokenIds.tk_divide_tilde()
      | TokenIds.tk_rem_tilde() | TokenIds.tk_lshift() | TokenIds.tk_rshift()
      | TokenIds.tk_eq() | TokenIds.tk_ne()
      | TokenIds.tk_le() | TokenIds.tk_ge()
      | TokenIds.tk_chain() | TokenIds.tk_funchain()
      | TokenIds.tk_subtype()
      | TokenIds.tk_at_lbrace() | TokenIds.tk_mod()
      | TokenIds.tk_minus_tilde_new()
      => (l, col + 1)
      // 1 character symbols
      | TokenIds.tk_backslash()
      | TokenIds.tk_lbrace() | TokenIds.tk_rbrace()
      | TokenIds.tk_lparen() | TokenIds.tk_rparen() | TokenIds.tk_call()
      | TokenIds.tk_lsquare() | TokenIds.tk_rsquare()
      | TokenIds.tk_comma() | TokenIds.tk_dot() | TokenIds.tk_tilde()
      | TokenIds.tk_colon() | TokenIds.tk_semi() | TokenIds.tk_assign()
      | TokenIds.tk_plus() | TokenIds.tk_minus() | TokenIds.tk_multiply()
      | TokenIds.tk_divide() | TokenIds.tk_rem() | TokenIds.tk_at()
      | TokenIds.tk_lt() | TokenIds.tk_gt()
      | TokenIds.tk_pipe() | TokenIds.tk_isecttype() | TokenIds.tk_ephemeral() | TokenIds.tk_aliased()
      | TokenIds.tk_question() | TokenIds.tk_unary_minus() | TokenIds.tk_constant()
      | TokenIds.tk_minus_new()
      => (l, col)
      // Keywords
      // 2 character keywords
      | TokenIds.tk_as() | TokenIds.tk_is() | TokenIds.tk_be()
      | TokenIds.tk_if() | TokenIds.tk_in() | TokenIds.tk_do()
      | TokenIds.tk_or()
      => (l, col + 1)
      // 3 character keywords
      | TokenIds.tk_use() | TokenIds.tk_var() | TokenIds.tk_let() | TokenIds.tk_fvar() | TokenIds.tk_flet()
      | TokenIds.tk_new() | TokenIds.tk_fun()
      | TokenIds.tk_iso() | TokenIds.tk_trn()| TokenIds.tk_ref()| TokenIds.tk_val()| TokenIds.tk_box()| TokenIds.tk_tag()
      | TokenIds.tk_end() | TokenIds.tk_for() | TokenIds.tk_try()
      | TokenIds.tk_not() | TokenIds.tk_and() | TokenIds.tk_xor()
      => (l, col + 2)
      // 4 character keywords
      | TokenIds.tk_type() | TokenIds.tk_isnt() | TokenIds.tk_this()
      | TokenIds.tk_then() | TokenIds.tk_else() | TokenIds.tk_with()
      | TokenIds.tk_true() | TokenIds.tk_false()
      | TokenIds.tk_cap_any()
      => (l, col + 3)
      // 5 character keywords
      | TokenIds.tk_trait() | TokenIds.tk_struct() | TokenIds.tk_class() | TokenIds.tk_actor()
      | TokenIds.tk_embed() | TokenIds.tk_break()
      | TokenIds.tk_ifdef() | TokenIds.tk_while()
      | TokenIds.tk_until() | TokenIds.tk_match() | TokenIds.tk_where()
      | TokenIds.tk_error() | TokenIds.tk_location()
      | TokenIds.tk_cap_read() | TokenIds.tk_cap_send()
      => (l, col + 4)
      // 6 character keywords
      | TokenIds.tk_object() | TokenIds.tk_return()
      | TokenIds.tk_iftype() | TokenIds.tk_elseif()
      | TokenIds.tk_repeat()
      | TokenIds.tk_cap_share() | TokenIds.tk_cap_alias()
      => (l, col + 5)
      // 7 character keywords
      | TokenIds.tk_consume() | TokenIds.tk_recover()
      => (l, col + 6)
      // 8 character keywords
      | TokenIds.tk_continue() | TokenIds.tk_digestof()
      => (l, col + 7)
      // 9 character keywords
      | TokenIds.tk_interface() | TokenIds.tk_primitive() | TokenIds.tk_address()
      => (l, col + 8)
      // 13 character keywords
      | TokenIds.tk_compile_error()
      => (l, col + 12)
      | TokenIds.tk_id() =>
        let s = try (token_value() as String val).size() - 1 else 0 end
        return (l, col + s)
      | TokenIds.tk_string() =>
        // we need to do some complex parsing
        // to get the actual string width including quotes
        let src = (source_contents() as String box)
        var offset = 
          if l == 1 then
            col - 1
          else
            let line_idx = src.find("\n" where nth = l - 2)?
            USize(line_idx.usize() + col)
          end
        var c = src(offset)?
        Debug("[STRING] FIRST C: " + String.from_utf32(c.u32()))
        var end_line = l
        var end_col = col
        var start_quotes = USize(0)
        var end_quotes = USize(0)
        // count starting quotes
        while c == U8('"') do
          start_quotes = start_quotes + 1
          offset = offset + 1
          c = src(offset)?
        end
        Debug("[STRING] " + start_quotes.string() + " - quoted string")

        while true do
          // check for \" escapes
          match c
          | '\\' => 
            // ignore next char and advance
            offset = offset + 1
            c = src(offset)?
            end_col = end_col + 1
            end_quotes = 0
          | '\n' => 
            end_line = end_line + 1
            end_col = 1
            end_quotes = 0
          | '"' =>
            end_quotes = end_quotes + 1
          else
            end_quotes = 0
          end

          // we have a matching number of quotes
          if end_quotes == start_quotes then
            // consume excess quotes
            while c == U8('"') do
              offset = offset + 1
              c = src(offset)?
              end_col = end_col + 1
            end
            Debug("[STRING] END: " + end_line.string() + ":" + end_col.string())
            return (end_line, end_col)
          end
          offset = offset + 1
          c = src(offset)?
          end_col = end_col + 1
        end
        None
      | TokenIds.tk_int() =>
        // check the source to get the width of the int
        let src  = source_contents() as String box
        var start_offset: USize = 
          if l == 1 then
            col - 1
          else
            let line_idx = src.find("\n" where nth = l - 2)?
            line_idx.usize() + col
          end
        let end_offset = _Num.int(src, start_offset)
        (l, col + (end_offset - start_offset))
      | TokenIds.tk_float() =>
        // float parsing
        let src = source_contents() as String box
        let start_offset: USize = 
          if l == 1 then
            col - 1
          else
            let line_idx = src.find("\n" where nth = l - 2)?
            line_idx.usize() + col
          end
        let end_offset = _Num.float(src, start_offset)
        let end_col = col + (end_offset - start_offset)
        Debug("[FLOAT] " + end_col.string())
        (l, end_col)
      end
    end


  fun _span(): ((USize, USize), (USize, USize)) =>
    // try to handle some quick special cases of AST nodes we know the width of
    match end_pos()
    | (let end_line: USize, let end_col: USize) =>
      return ((line(), pos()), (end_line, end_col))
    end

    // for the generic cases use our good ole visitor
    let visitor =
      object is ASTVisitor
        var max_pos: (USize, USize) = (0, 0)
        var min_pos: (USize, USize) = (USize.max_value(), USize.max_value())

        fun ref visit(ast: AST box): VisitResult =>
          let cur_min = (ast.line(), ast.pos())
          let cur_max = match ast.end_pos()
          | (let e_line: USize, let e_pos: USize) => (e_line, e_pos)
          | None => cur_min
          end
          if (cur_max._1 > max_pos._1) or ((cur_max._1 == max_pos._1) and (cur_max._2 > max_pos._2)) then
            max_pos = cur_max
          end
          if (cur_min._1 < min_pos._1) or ((cur_min._1 == min_pos._1) and (cur_min._2 < min_pos._2)) then
            min_pos = cur_min
          end
          Continue

        fun ref leave(ast: AST box): VisitResult =>
          Continue

        fun max(): (USize, USize) => max_pos
        fun min(): (USize, USize) => min_pos
      end
    visit(visitor)
    (visitor.min(), visitor.max())


  // fun find_node_at(line': USize, column': USize): (AST box | None) =>
  //   match _find_node_at(line', column')
  //   | let found: AST box => found._refine()
  //   end

  // fun _find_node_at(line': USize, column': USize): (AST box | None) =>
  //   // find a first node on or after the column and line we search for
  //   let result: FindNodeResult box = _find_node_at_pos(line', column')
  //   match (result.before, result.after)
  //   | (let before: AST box, let after: AST box) =>
  //     // we have a node with higher pos after this one
  //     // so we can be sure our node is in here
  //     Debug("before: " + before.debug())
  //     Debug("after: " + after.debug())
  //     // TODO: check size of before node
  //     if after.infix_node() then
  //       // second one is an infix node, check its bounds
  //       (let min, let max) = before._span()
  //       if (min._1 < line') or ((min._1 == line') and (min._2 <= column')) then
  //         // infix min position is before searched position, we need to proceed
  //         // here
  //         return match after._find_node_at(line', column')
  //         | let found: AST box => found
  //         else
  //           before
  //         end
  //       end
  //     end
  //     if before.child() isnt None then
  //       return match before._find_node_at(line', column')
  //         | let found: AST box => found
  //         else
  //           before
  //         end
  //     else
  //       // we have a leaf node
  //       return before
  //     end
  //   | (let before: AST box, None) =>
  //     Debug("last node, checking span...")
  //     // there is no other node after the before node
  //     // check the span to see if we can be inside it
  //     (let min, let max) = before._span()
  //     Debug("SPAN: " + min._1.string() + ":" + min._2.string() + " - " + max._1.string() + ":" + max._2.string())
  //     if (max._1 >= line') and (max._2 >= column') then
  //       // we can be inside
  //       if before.child() isnt None then
  //         return match before._find_node_at(line', column')
  //           | let found: AST box => found
  //           else
  //             before
  //           end
  //       else
  //         return before
  //       end
  //     end
  //   | (None, let after: AST box) =>
  //     Debug("Only found after: " + after.debug())
  //     if after.infix_node() then
  //       // an infix node might have a left child whose position if before the
  //       // position reported by the infix node itself, so check the lhs child
  //       match after.child()
  //       | let ac: AST box =>
  //         return ac._find_node_at(line', column')
  //       end
  //     end
  //   end
  //   None

  
interface ASTVisitor
  fun ref visit(ast: AST box): VisitResult
    """
    Visit an AST node, return `Continue` if traversing
    the AST should continue, `Stop` if it should stop.
    """

  fun ref leave(ast: AST box): VisitResult =>
    """
    Signal that we are done with all the children of this ast node.
    Return `Continue` if traversing the AST should continue, `Continue` if it should stop.
    """
    Continue

primitive Continue is Equatable[VisitResult]
  fun string(): String iso^ =>
    recover iso
      String.create(8) .> append("Continue")
    end

primitive Stop is Equatable[VisitResult]
  fun string(): String iso^ =>
    recover iso
      String.create(4) .> append("Stop")
    end

type VisitResult is (Continue | Stop)

class _ASTFindNodeVisitor
  let _predicate: {(AST box): Bool}
  let _stop_if: {(AST box): Bool}

  var _node: (AST box | None) = None

  new create(
    predicate': {(AST box): Bool},
    stop_if': {(AST box): Bool}
  ) =>
    _predicate = predicate'
    _stop_if = stop_if'

  fun ref visit(ast: AST box): VisitResult =>
    if _predicate(ast) then
      Debug("found node " + ast.debug())
      _node = ast
      Stop
    else
      if _stop_if(ast) then
        Stop
      else
        Continue
      end
    end

  fun ref leave(ast: AST box): VisitResult => Continue

  fun box node(): (AST box | None) => _node

class _ASTReorderedChildIter is Iterator[AST]
  """
  Iterator through the direct children of a parent AST,
  that has been reordered by the parser.
  We want to visit it in the order it appeared in the source,
  so we need to re-reorder it.
  """
  let _parent: AST box
  let _indices: Array[USize] box
  var _current: USize
  new ref create(ast: AST box, indices: Array[USize] box) =>
    _parent = ast
    _indices = indices
    _current = 0

  fun ref has_next(): Bool =>
    _current < _indices.size()

  fun ref next(): AST ? =>
    let idx = _indices(_current = _current + 1)?
    _parent(idx)?


class _ASTChildIter is Iterator[AST]
  """
  Iterator through the direct children of a parent AST.
  """
  var _child: (AST | None)

  new ref create(ast: AST box) =>
    _child = ast.child()

  fun ref has_next(): Bool =>
    _child isnt None

  fun ref next(): AST ? =>
    let child = _child as AST
    _child = child.sibling()
    child
