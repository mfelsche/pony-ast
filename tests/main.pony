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
    test(_FindTypes)

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

class \nodoc\ iso _FindTypes is UnitTest
  let expected: Array[(USize, USize, String val)] val = [
    (4, 7, "String val") // field name
    (6, 16, "Env val")   // param name
    (6, 20, "Env val")   // param type
    (7, 6, "String val") // field ref
    (9, 11, "String val")  // String type ref
    (9, 21, "String ref^") // String.create
    (9, 23, "USize val")   // literal int argument to String.create
    (9, 24, "USize val")   // literal int argument to String.create
  ]

  fun name(): String => "find-types"

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

          for (line, column, expected_type) in expected.values() do
            match module.find_node_at(line, column)
            | let ast: AST box =>
              Debug("FOUND " + TokenIds.string(ast.id()))
              match Types.get_ast_type(ast)
              | let found_type: String =>
                h.assert_eq[String val](expected_type, found_type, "Error at " + line.string() + ":" + column.string())
              | None =>
                h.fail("No Type found for node " + TokenIds.string(ast.id()) + " at " + line.string() + ":" + column.string())
                return
              end
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

