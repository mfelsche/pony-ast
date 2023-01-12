actor Main
  new create(env: Env) =>
    try
      let foo = env.args(0)?
    end
    env.out.print("Foo")

  fun ref none(param: String = "foo"): Main =>
    [as U8:]
    this
