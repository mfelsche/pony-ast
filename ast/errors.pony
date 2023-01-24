use @errors_alloc[NullablePointer[_Errors]]()
use @errors_free[None](errors: _Errors)
use @errors_print[None](errors: _Errors)
use @errors_get_first[NullablePointer[_ErrorMsg]](errors: _Errors)
use @errors_get_count[USize](errors: _Errors)

struct _TypecheckFrame
  var package: Pointer[_AST] ref = package.create()
  var module: Pointer[_AST] ref = module.create()
  var ttype: Pointer[_AST] ref = ttype.create()
  var constraint: Pointer[_AST] ref = constraint.create()
  var provides: Pointer[_AST] ref = provides.create()
  var method: Pointer[_AST] ref = method.create()
  var def_arg: Pointer[_AST] ref = def_arg.create()
  var method_body: Pointer[_AST] ref = method_body.create()
  var method_params: Pointer[_AST] ref = method_params.create()
  var method_type: Pointer[_AST] ref = method_type.create()
  var ffi_type: Pointer[_AST] ref = ffi_type.create()
  var as_type: Pointer[_AST] ref = as_type.create()
  var the_case: Pointer[_AST] ref = the_case.create()
  var pattern: Pointer[_AST] ref = pattern.create()
  var loop: Pointer[_AST] ref = loop.create()
  var loop_cond: Pointer[_AST] ref = loop_cond.create()
  var loop_body: Pointer[_AST] ref = loop_body.create()
  var loop_else: Pointer[_AST] ref = loop_else.create()
  var try_expr: Pointer[_AST] ref = try_expr.create()
  var rrecover: Pointer[_AST] ref = rrecover.create()
  var ifdef_cond: Pointer[_AST] ref = ifdef_cond.create()
  var ifdef_clause: Pointer[_AST] ref = ifdef_clause.create()
  var iftype_constraint: Pointer[_AST] ref = iftype_constraint.create()
  var iftype_body: Pointer[_AST] ref = iftype_body.create()

  var prev: NullablePointer[_TypecheckFrame] ref = prev.none()


struct _TypecheckStats
  var names_count: USize = 0
  var default_caps_count: USize = 0
  var heap_alloc: USize = 0
  var stack_alloc: USize = 0


class Error
  let file: (String val | None)
    """
    Absolute path to the file containing this error.

    Is `None` for errors without file context.
    """
  let line: USize
  let pos: USize
  let msg: String
    """
    Error Message.
    """
  let infos: Array[Error]
    """
    Additional informational messages, possibly with a file context.
    """
  let source_snippet: (String val | None)
    """
    Used for displaying the error message in the context of the source.

    Is `None` for errors without file context.
    """

  new create(msg': _ErrorMsg box) =>
    """
    Copy out all the error information, so the ErrorMsg can be deleted afterwards
    """
    let file_ptr = msg'.file
    file =
      if file_ptr.is_null() then
        None
      else
        recover val String.copy_cstring(file_ptr) end
      end
    line = msg'.line
    pos = msg'.pos
    let msg_ptr = msg'.msg
    msg = recover val String.copy_cstring(msg_ptr) end
    let src_ptr = msg'.source
    source_snippet =
      if src_ptr.is_null() then
        None
      else
        recover val String.copy_cstring(src_ptr) end
      end

    var frame_ptr = msg'.frame
    infos = Array[Error].create(0)
    while not frame_ptr.is_none() do
      try
        let frame: _ErrorMsg box = frame_ptr()?
        infos.push(Error.create(frame))
        frame_ptr = frame.frame
      end
    end

  new message(message': String val) =>
    """
    Create an error with file context, only containing the given `message`.
    """
    file = None
    line = 0
    pos = 0
    msg = message'
    source_snippet = None
    infos = Array[Error].create(0)

  fun has_file_context(): Bool =>
    (file isnt None) and (line > 0) and (pos > 0)


struct _ErrorMsg
  var file: Pointer[U8] val = recover val file.create() end
  var line: USize = 0
  var pos: USize = 0
  var msg: Pointer[U8] val = recover val msg.create() end
  var source: Pointer[U8] val = recover val source.create() end
  var frame: NullablePointer[_ErrorMsg] ref = frame.none()
  var next: NullablePointer[_ErrorMsg] ref = next.none()

struct _FILE
  """STUB"""

struct _Errors
  var head: NullablePointer[_ErrorMsg] = head.none()
  var tail: NullablePointer[_ErrorMsg] = tail.none()
  var count: USize = 0
  var immediate_report: Bool = false
  var output_stream: Pointer[I32] = output_stream.create() // FILE*

  fun extract(): Array[Error] =>
    let errs = Array[Error].create(this.count)
    var msg_ptr: NullablePointer[_ErrorMsg] box = head
    while not msg_ptr.is_none() do
      try
        let msg: _ErrorMsg box = msg_ptr()?
        errs.push(Error.create(msg))
        msg_ptr = msg.next
      end
    end
    errs

struct _Typecheck
  """
  """
  var frame: NullablePointer[_TypecheckFrame] ref
  embed stats: _TypecheckStats
  var errors: NullablePointer[_Errors]

  new create() =>
    """
    no allocation
    """
    frame = NullablePointer[_TypecheckFrame].none()
    stats = _TypecheckStats.create()
    errors = NullablePointer[_Errors].none()

