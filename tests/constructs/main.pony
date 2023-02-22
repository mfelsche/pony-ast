use "collections"

actor Main
  var name: String

  new create(env: Env) =>
    name =
      recover val
        String.create(10) .> append("snot")
      end
    env.out.print(name)

trait Snot
  fun bla(): U8

  fun blubb(): Bool => bla() == U8(0xFF)

class Foo is Snot
  """
  docstring
  """

  var variable: (Array[String] iso | None) = None
  embed s: String = String.create(0b10)
  let immutable: Map[String, USize]

  fun bla(): U8 => F32(0.12345e-4).u8()

  fun with_default(arg: String tag, len: USize = -1) =>
    None
