use @errors_alloc[NullablePointer[_Errors]]()
use @errors_free[None](errors: _Errors)
use @errors_print[None](errors: _Errors)
use @errors_get_first[NullablePointer[_ErrorMsg]](errors: _Errors)
use @errors_get_count[USize](errors: _Errors)

struct _TypecheckFrame
  var package: NullablePointer[_AST] ref = package.none()
  var module: NullablePointer[_AST] ref = module.none()
  var ttype: NullablePointer[_AST] ref = ttype.none()
  var constraint: NullablePointer[_AST] ref = constraint.none()
  var provides: NullablePointer[_AST] ref = provides.none()
  var method: NullablePointer[_AST] ref = method.none()
  var def_arg: NullablePointer[_AST] ref = def_arg.none()
  var method_body: NullablePointer[_AST] ref = method_body.none()
  var method_params: NullablePointer[_AST] ref = method_params.none()
  var method_type: NullablePointer[_AST] ref = method_type.none()
  var ffi_type: NullablePointer[_AST] ref = ffi_type.none()
  var as_type: NullablePointer[_AST] ref = as_type.none()
  var the_case: NullablePointer[_AST] ref = the_case.none()
  var pattern: NullablePointer[_AST] ref = pattern.none()
  var loop: NullablePointer[_AST] ref = loop.none()
  var loop_cond: NullablePointer[_AST] ref = loop_cond.none()
  var loop_body: NullablePointer[_AST] ref = loop_body.none()
  var loop_else: NullablePointer[_AST] ref = loop_else.none()
  var try_expr: NullablePointer[_AST] ref = try_expr.none()
  var rrecover: NullablePointer[_AST] ref = rrecover.none()
  var ifdef_cond: NullablePointer[_AST] ref = ifdef_cond.none()
  var ifdef_clause: NullablePointer[_AST] ref = ifdef_clause.none()
  var iftype_constraint: NullablePointer[_AST] ref = iftype_constraint.none()
  var iftype_body: NullablePointer[_AST] ref = iftype_body.none()

  var prev: NullablePointer[_TypecheckFrame] ref = prev.none()


struct _TypecheckStats
  var names_count: USize = 0
  var default_caps_count: USize = 0
  var heap_alloc: USize = 0
  var stack_alloc: USize = 0


class Error
  let file: String val
  let line: USize
  let pos: USize
  let msg: String
  let infos: Array[Error]
  let source_snippet: String val
    """used for displaying the error message in the context of the source"""

  new create(msg': _ErrorMsg box) =>
    """
    Copy out all the error information, so the ErrorMsg can be deleted afterwards
    """
    let file_ptr = msg'.file
    file = recover val String.copy_cstring(file_ptr) end
    line = msg'.line
    pos = msg'.pos
    let msg_ptr = msg'.msg
    msg = recover val String.copy_cstring(msg_ptr) end
    let src_ptr = msg'.source
    source_snippet = recover val String.copy_cstring(src_ptr) end

    var frame_ptr = msg'.frame
    infos = Array[Error].create(0)
    while not frame_ptr.is_none() do
      try
        let frame: _ErrorMsg box = frame_ptr()?
        infos.push(Error.create(frame))
        frame_ptr = frame.frame
      end
    end


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

