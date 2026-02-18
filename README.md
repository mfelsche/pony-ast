# Pony-AST :horse: :deciduous_tree:

Pony library wrapping `libponyc` via C-FFI, so Pony programs can finally compile themselves. :horse: :point_right: :horse:

## Current Status

This software is considered in beta status. It is mainly used within the [`pony-lsp` (The Pony Language Server)](https://github.com/ponylang/ponyc/tree/main/tools/pony-lsp), so it is getting some usage and thus testing.

It is tested upon every PR on CI against the latest ponyc. As it is relying on FFI heavily, it might, in very subtle ways, undermine the Memory Safety Guarantees that Pony otherwise provides. So, use with care.

## Requirements

In order to make the current compiler work, and have it pick up the Pony standard library one needs to point the `PONYPATH` environment variable to the pony stdlib. If you have a pony installation you compiled yourself, it will most likely live in: `ponyc-repository/packages`. If you have a pre-compiled installation obtained via ponyup it might live in something like: `$HOME/.local/share/ponyup/ponyc-release-<RELEASE-NUMBER>-<ARCH>-<SYSTEM>/packages`.

## Compatibility

`pony-ast` is tightly bound to a specific version (or range of versions) of ponyc as it is interfacing with ponyc internals and if those change, `pony-ast` might not build or fail in surprising ways during runtime.

| Ponyc      | pony-ast |
| -----------| -------- |
| <  0.58.10 | 0.3.2    |
| >= 0.58.10 | 0.4.0    |

## Usage

The main entrypoint is the Compiler, that is running the pony compiler passes until a provided pass and is emitting the produced `ast_t` structure in the `Program` class. It can be used to access packages, modules and entities, retrieve AST nodes at certain positions, go to definitions etc. etc.

```pony
use ast = "ast"

actor Main
  new create(env: Env) =>
    try
      let path = FilePath(FileAuth(env.root), env.args(env.args.size() - 1)?)
      match ast.Compiler.compile(
        path
        where
          pass = ast.PassExpr,
          package_search_paths = ["/path/to/pony/stdlib"]
      )
      | let program: ast.Program =>
        // do something with the parsed program AST
        env.out.print("OK")
      | let errors: Array[ast.Error] =>
        // do something with the compilation errors
        for e in errors.values() do
          env.err.print(e.msg)
        end
      end
    end
```

For more examples, have a look at the [`examples` directory](./examples)
