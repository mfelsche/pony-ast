use "debug"

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

  fun box children(): _ASTChildIter =>
    _ASTChildIter(this)

  fun box num_children(): USize =>
    @ast_childcount(raw)

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
      source()()?.contents()
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
    // TODO: skip nodes not being set i.e. TK_NONE
    let filter_none: Bool =
      match id()
      | TokenIds.tk_call() | TokenIds.tk_typeref() => true
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
      false
    end

  fun _find_node_at_pos(line': USize, column': USize): FindNodeResult box =>
    let visitor =
      object is ASTVisitor
        var _res: FindNodeResult = FindNodeResult
        let _line: USize = line'
        let _column: USize = column'

        fun ref visit(ast: AST box): VisitResult =>
          if (ast.line() < _line) or ((ast.line() == _line) and (ast.pos() <= _column)) then
            _res.before = ast
            Continue
          elseif (ast.line() > _line) or ((ast.line() == _line) and (ast.pos() > _column)) then
            _res.after = ast
            Stop
          else
            // shouldn't happen
            Debug("Shouldn't happen, but it did!")
            Stop
          end

        fun ref leave(ast: AST box): VisitResult => Continue

        fun res(): FindNodeResult box => _res
      end
    visit(visitor)
    visitor.res()

  fun _span(): ((USize, USize), (USize, USize)) =>
    let l = line()
    let col = pos()


    // try to handle some quick special cases of AST nodes we know the width of
    try
      match id()
      | TokenIds.tk_id() =>
        let s = try (token_value() as String val).size() else 0 end
        return ((l, col), (l, col + s))
      | TokenIds.tk_string() =>
        let s = try (token_value() as String val).size() else 0 end
        return ((l, col), (l, col + 1))
      | TokenIds.tk_int() =>
        // check the source to get the width of the int
        // TODO: this is costly
        let lines = (source_contents() as String box).split_by("\n")
        let token_line = lines(l - 1)?
        var offset: USize = col - 1
        var len: USize = 0
        let predicate =
          if token_line(offset)? == '0' then
            if token_line(offset + 1)? == 'x' then
              offset = offset + 2
              len = 2
              // hexadecimal
              _ASCII~is_hexadecimal()
            elseif token_line(offset + 1)? == 'b' then
              offset = offset + 2
              len = 2
              // binary
              _ASCII~is_binary()
            else
              // a number starting with zero
              _ASCII~is_decimal()
            end
          else
            _ASCII~is_decimal()
          end
        var c = token_line(offset)?
        while predicate(c) do
          len = len + 1
          offset = offset + 1
          c = token_line(offset)?
        end
        ((l, col), (l, col + len))
      | TokenIds.tk_call() =>
        Debug("Getting span of TK_CALL")
        let lhs = this(0)? // first child is LHS
        let lhs_min = lhs._span()._1
        let partial = this(3)? // third child is optional question mark
        (lhs_min, (partial.line(), partial.pos()))
      end
    end
    // for the generic cases use our good ole visitor
    let visitor =
      object is ASTVisitor
        var max_pos: (USize, USize) = (0, 0)
        var min_pos: (USize, USize) = (USize.max_value(), USize.max_value())
        fun ref visit(ast: AST box): VisitResult =>
          let line = ast.line()
          let col  = ast.pos()
          if (line > max_pos._1) or ((line == max_pos._1) and (col > max_pos._2)) then
            max_pos = (line, col)
          end

          if (line < min_pos._1) or ((line == min_pos._1) and (col < min_pos._2)) then
            min_pos = (line, col)
          end
          Continue

        fun ref leave(ast: AST box): VisitResult =>
          Continue

        fun max(): (USize, USize) => max_pos
        fun min(): (USize, USize) => min_pos
      end
    visit(visitor)
    (visitor.min(), visitor.max())

  fun find_node_at(line': USize, column': USize): (AST box | None) =>
    // TODO: refine node - take some logic that is now in types.pony here
    //                   - chose more meaningful nodes than TK_NONE or TK_ID
    let source' = source_file()
    // find a first node on or after the column and line we search for
    var result: FindNodeResult box = _find_node_at_pos(line', column')
    while true do
      match (result.before, result.after)
      | (let before: AST box, let after: AST box) =>
        // we have a node with higher pos after this one
        // so we can be sure our node is in here
        Debug("before: " + before.debug())
        Debug("after: " + after.debug())
        if before.child() isnt None then
          result = before._find_node_at_pos(line', column')
        else
          // we have a leaf node
          return before
        end
      | (let before: AST box, None) =>
        Debug("last node, checking span...")
        // there is no other node after the before node
        // check the span to see if we can be inside it
        (let min, let max) = before._span()
        Debug("SPAN: " + min._1.string() + ":" + min._2.string() + " - " + max._1.string() + ":" + max._2.string())
        if (max._1 >= line') and (max._2 >= column') then
          // we can be inside
          if before.child() isnt None then
            result = before._find_node_at_pos(line', column')
          else
            return before
          end
        else
          // the before node lies way before our desired position
          break
        end
      | (None, let after: AST box) =>
        if after.infix_node() then
          match after.child()
          | let ac: AST box =>
            result = ac._find_node_at_pos(line', column')
          else
            break
          end
        else
          break
        end
      end
    end
    None



    /*

        let node_pos = node.pos()
        if node_pos <= column' then
          // TODO: refine to a meaningful node
          match node.id()
          | TokenIds.tk_call() =>
            // our node is somewhere in the arguments, go to the first one
            let pos_args = node(1)?
            if pos_args.id() == TokenIds.tk_none() then
              let named_args = node(2)?
              named_args.find_node_at(line', column')
            else
              pos_args.find_node_at(line', column')
            end
          | TokenIds.tk_positionalargs() =>
            // lets check the arguments
            match node.child()
            | let nc: AST box =>
              nc.find_node_at(line', column')
            end
          else
            node
          end
        elseif node_pos > column' then
          // current node_pos is > column'
          // check the more accurate span
          (let min, let max) = node._span()
          Debug("SPAN: " + min._1.string() + ":" + min._2.string() + " - " + max._1.string() + ":" + max._2.string())
          if ((min._1 <= line') and (min._2 <= column'))
             and
             ((line' <= max._1) and (column' <= max._2))
          then
            // node definitely contains our position
            if node.num_children() > 0 then
              // try to find a more concrete node, possibly a leaf
              match node.find_node_at(line', column')
              | let found: AST box =>
                return found
              end
              None // this shouldn't happen
            else
              // no children and within span, this is our node
              node
            end
          else
            None
          end
        end
      end
    end
    */

  fun _refine(): (AST box | None) =>
    match id()
    | TokenIds.tk_positionalargs() =>
      child()
    else
      this
    end


interface ASTVisitor
  fun ref visit(ast: AST box): VisitResult
    """
    Visit an AST node, return `true` if traversing
    the AST should continue, `false` if it should stop.
    """

  fun ref leave(ast: AST box): VisitResult =>
    """
    Signal that we are done with all the children of this ast node.
    Return `true` if traversing the AST should continue, `false` if it should stop.
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


class FindNodeResult
  var before: (AST box | None) = None
  var after: (AST box | None) = None

class _ASTFindNodeVisitor
  let _predicate: {(AST box): Bool}
  let _stop_if: {(AST box): Bool}

  var _node: (AST box | None) = None

  new create(
    predicate': {(AST box): Bool},
    stop_if': {(AST box): Bool}) =>
    _predicate = predicate'
    _stop_if = stop_if'

  fun ref visit(ast: AST box): VisitResult =>
    if _predicate(ast) then
      Debug("found node " + TokenIds.string(ast.id()))
      _node = ast
      Stop
    else
      // turn stop-if condition into carry-on condition
      if _stop_if(ast) then
        Stop
      else
        Continue
      end
    end

  fun ref leave(ast: AST box): VisitResult => Continue

  fun box node(): (AST box | None) => _node


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
