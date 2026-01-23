actor Main
  new create(env: Env) =>
    None


  fun ref none(param: String = "foo"): Main =>
    [as U8:]
    this.bla()
    bla()
    this

  fun bla(): Bool => true
