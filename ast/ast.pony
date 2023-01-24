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

  fun box source(): NullablePointer[_Source] =>
    """
    The source struct for this AST.
    Will only return a non-NULL pointer
    if this AST represents a module
    """
    @ast_source(raw)

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
    try
      let type_ast = ast_type() as AST
      let type_str_ptr = @ast_print_type(type_ast.raw)
      recover val String.copy_cstring(type_str_ptr) end
    end

  fun box type_string(): (String | None) =>
    """
    Prints ASTs representing types. e.g. obtained with `ast_type()`
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


class _ASTChildIter is Iterator[AST]
  var _child: (AST | None)

  new ref create(ast: AST box) =>
    _child = ast.child()

  fun ref has_next(): Bool =>
    _child isnt None

  fun ref next(): AST ? =>
    let child = _child as AST
    _child = child.sibling()
    child
