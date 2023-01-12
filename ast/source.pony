use @source_open[NullablePointer[_Source]](file: Pointer[U8] tag, error_msgp: NullablePointer[Pointer[U8]])
use @source_open_string[NullablePointer[_Source]](source_code: Pointer[U8] tag)
use @source_close[None](source: _Source)

struct _Source
  let file: Pointer[U8] val = file.create()
  let m: Pointer[U8] ref = m.create()
  let len: USize = 0
