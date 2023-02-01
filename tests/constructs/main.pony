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
  embed s: String = String.create(10)
  let immutable: Map[String, USize]

  fun bla(): U8 => U8(0x0F)

  fun with_default(arg: String tag, len: USize = -1) =>
    None
