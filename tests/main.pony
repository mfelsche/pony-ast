use "debug"
use "files"
use "pony_test"
use "../ast"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_CompileSimple)
    test(_CompileRepeatedly)
    test(_PositionIndexFind)
    // test(_FindTypes)

class \nodoc\ iso _CompileSimple is UnitTest
  fun name(): String => "compile/simple"

  fun apply(h: TestHelper) =>
    let source_dir = Path.join(Path.dir(__loc.file()), "simple")
    let pony_path =
      try
        PonyPath(h.env) as String
      else
        h.fail("PONYPATH not set")
        return
      end
    match Compiler.compile(FilePath(FileAuth(h.env.root), source_dir), [pony_path])
    | let p: Program =>
      try
        let pkg = p.package() as Package
        h.assert_eq[String](source_dir, pkg.path)
      else
        h.fail("No package, huh?")
      end
    | let e: Array[Error] =>
      h.fail(
        "Compiling the simple example failed with: " +
        try
          e(0)?.msg
        else
          "0 errors"
        end)
    end

class \nodoc\ iso _CompileRepeatedly is UnitTest
  fun name(): String => "compile/repeatedly"

  fun apply(h: TestHelper) =>
    let source_dir = Path.join(Path.dir(__loc.file()), "simple")
    let pony_path =
      try
        PonyPath(h.env) as String
      else
        h.fail("PONYPATH not set")
        return
      end
    var rounds: USize = 3
    while rounds > 0 do
      match Compiler.compile(FilePath(FileAuth(h.env.root), source_dir), [pony_path])
      | let p: Program =>
        try
          let pkg = p.package() as Package
          h.assert_eq[String](source_dir, pkg.path)
        else
          h.fail("No package, huh?")
        end
      | let e: Array[Error] =>
        h.fail(
          "Compiling the simple example failed with: " +
          try
            e(0)?.msg
          else
            "0 errors"
          end)
      end
      rounds = rounds - 1
    end

// class \nodoc\ iso _FindTypes is UnitTest
//   let expected: Array[(USize, USize, String val)] val = [
//     (4, 7, "String val") // field name
//     (6, 16, "Env val")   // param name
//     (6, 20, "Env val")   // param type
//     (7, 6, "String val") // field ref
//     (9, 11, "String val")  // String type ref
//     (9, 21, "String ref^") // String.create
//     (9, 23, "USize val")   // literal int argument to String.create
//     (9, 24, "USize val")   // literal int argument to String.create
//   ]

//   fun name(): String => "find-types"

//   fun apply(h: TestHelper) =>
//     let source_dir = Path.join(Path.dir(__loc.file()), "constructs")
//     let pony_path =
//       try
//         PonyPath(h.env) as String
//       else
//         h.fail("PONYPATH not set")
//         return
//       end
//     match Compiler.compile(FilePath(FileAuth(h.env.root), source_dir), [pony_path])
//     | let p: Program =>
//       try
//         let pkg = p.package() as Package
//         h.assert_eq[String](source_dir, pkg.path)
//         let main_pony_path = Path.join(source_dir, "main.pony")
//         try
//           let module = pkg.find_module(main_pony_path) as Module

//           for (line, column, expected_type) in expected.values() do
//             match module.find_node_at(line, column)
//             | let ast: AST box =>
//               Debug("FOUND " + TokenIds.string(ast.id()))
//               match Types.get_ast_type(ast)
//               | let found_type: String =>
//                 h.assert_eq[String val](expected_type, found_type, "Error at " + line.string() + ":" + column.string())
//               | None =>
//                 h.fail("No Type found for node " + TokenIds.string(ast.id()) + " at " + line.string() + ":" + column.string())
//                 return
//               end
//             | None =>
//               h.fail("No AST node found at " + line.string() + ":" + column.string())
//               return
//             end

//           end
//         else
//           h.fail("No module with file " + main_pony_path)
//           return
//         end
//       else
//         h.fail("No package, huh?")
//         return
//       end
//     | let e: Array[Error] =>
//       h.fail(
//         "Compiling the constructs example failed with: " +
//         try
//           e(0)?.msg + " " + e(0)?.line.string() + ":" + e(0)?.pos.string()
//         else
//           "0 errors"
//         end)
//     end

class iso _PositionIndexFind is UnitTest
  let expected: Array[(USize, USize, TokenId)] val = [
    (1, 1, TokenIds.tk_use()) // use
    (1, 5, TokenIds.tk_string()) // use url
    (1, 17, TokenIds.tk_string()) // end of use url
    (3, 2, TokenIds.tk_actor()) // actor keyword
    (3, 7, TokenIds.tk_id()) // actor name
    (4, 4, TokenIds.tk_fvar()) // var field
    (4, 7, TokenIds.tk_fvar()) // field name
    (6, 3, TokenIds.tk_new()) // constructor begin
    (6, 7, TokenIds.tk_new())  // constructor name
    (6, 16, TokenIds.tk_param())   // param name
    (6, 20, TokenIds.tk_nominal())   // param type
    (7, 6, TokenIds.tk_fvarref()) // field ref
    (9, 11, TokenIds.tk_typeref())  // String type ref
    (9, 21, TokenIds.tk_newref()) // String.create
    (9, 23, TokenIds.tk_int())   // literal int argument to String.create
    (9, 24, TokenIds.tk_int())   // literal int argument to String.create
    (9, 28, TokenIds.tk_funchain()) // .>
    (9, 31, TokenIds.tk_funchain()) // append
    (9, 38, TokenIds.tk_string()) // "snot"
    (11, 7, TokenIds.tk_paramref()) // env
    (11, 8, TokenIds.tk_fletref()) // env.out <- the dot
    (11, 9, TokenIds.tk_fletref()) // env.out <- out
    (11, 12, TokenIds.tk_beref()) // env.out.print <- the second dot
    (11, 13, TokenIds.tk_beref()) // print
    (11, 18, TokenIds.tk_call()) // (
    (11, 19, TokenIds.tk_fvarref()) // name <- field reference as param
    (13, 3, TokenIds.tk_trait()) // trait
    (13, 9, TokenIds.tk_id()) // trait name
    (14, 5, TokenIds.tk_fun()) // fun keyword
    (14, 7, TokenIds.tk_fun()) // fun name
    (14, 14, TokenIds.tk_nominal()) // return type
    (16, 3, TokenIds.tk_fun()) // fun keyword
    (16, 7, TokenIds.tk_fun()) // fun name
    (16, 16, TokenIds.tk_nominal()) // return type
    (16, 24, TokenIds.tk_funref()) // reference to bla
    (16, 27, TokenIds.tk_call()) // start of call arguments
    (16, 30, TokenIds.tk_call()) // desugared `==` operator to call to `eq`
    (16, 33, TokenIds.tk_newref()) // reference to the constructor
    (16, 35, TokenIds.tk_call()) // call of the constructor
    (16, 36, TokenIds.tk_int()) // integer argument
    (18, 1, TokenIds.tk_class()) // class keyword
    (18, 7, TokenIds.tk_id()) // class name
    (18, 14, TokenIds.tk_nominal()) // provided type `Snot`
    (19, 3, TokenIds.tk_string()) // docstring first line
    (20, 1, TokenIds.tk_string()) // docstring second line beginning
    (20, 11, TokenIds.tk_string()) // docstring second line end
    (21, 5, TokenIds.tk_string()) // last ending quote of triple-quote
    (23, 3, TokenIds.tk_fvar()) // var keyword
    (23, 7, TokenIds.tk_fvar()) // var name
    (23, 18, TokenIds.tk_nominal()) // Array
    (23, 24, TokenIds.tk_nominal()) // String type argument
    (23, 32, TokenIds.tk_nominal()) // the iso part
    (23, 36, TokenIds.tk_uniontype()) // the union pipe
    (23, 38, TokenIds.tk_nominal()) // None initializer
    (24, 3, TokenIds.tk_embed()) // embed keyword
    (24, 9, TokenIds.tk_embed()) // embed name
    (24, 12, TokenIds.tk_nominal()) // String type
    (24, 21, TokenIds.tk_typeref()) // String type ref in initializer as part of constructor call
    (24, 27, TokenIds.tk_newref()) // reference to the constructor, the dot
    (24, 28, TokenIds.tk_newref()) // reference to the constructor
    (24, 34, TokenIds.tk_call()) // constructor call
    (24, 35, TokenIds.tk_int()) // binary int argument
    (24, 38, TokenIds.tk_int()) // binary int argument - end
    (25, 7, TokenIds.tk_flet()) // immutable field name
    (27, 20, TokenIds.tk_newref()) // reference to F32 constructor
    (27, 23, TokenIds.tk_call()) // constructor call
    (27, 24, TokenIds.tk_float()) // float literal start
    (27, 32, TokenIds.tk_float()) // float literal end
    (27, 35, TokenIds.tk_funref()) // .u8() - the dot
  ]


  fun name(): String => "position-index/find"

  fun apply(h: TestHelper) =>
    let source_dir = Path.join(Path.dir(__loc.file()), "constructs")
    let pony_path =
      try
        PonyPath(h.env) as String
      else
        h.fail("PONYPATH not set")
        return
      end
    match Compiler.compile(FilePath(FileAuth(h.env.root), source_dir), [pony_path])
    | let p: Program =>
      try
        let pkg = p.package() as Package
        h.assert_eq[String](source_dir, pkg.path)
        let main_pony_path = Path.join(source_dir, "main.pony")
        try
          let module = pkg.find_module(main_pony_path) as Module
          let index = module.create_position_index()
          index.debug(h.env.out)

          for (line, column, expected_token_id) in expected.values() do
            match index.find_node_at(line, column)
            | let ast: AST box =>
              h.assert_eq[String val](
                TokenIds.string(expected_token_id),
                TokenIds.string(ast.id()),
                "Found wrong node at " + line.string() + ":" + column.string() + ": " + ast.debug())
            | None =>
              h.fail("No AST node found at " + line.string() + ":" + column.string())
              return
            end

          end
        else
          h.fail("No module with file " + main_pony_path)
          return
        end
      else
        h.fail("No package, huh?")
        return
      end
    | let e: Array[Error] =>
      h.fail(
        "Compiling the constructs example failed with: " +
        try
          e(0)?.msg + " " + e(0)?.line.string() + ":" + e(0)?.pos.string()
        else
          "0 errors"
        end)
    end


