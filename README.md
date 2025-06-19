# Curriculum of Packaging Academy

The packaging Academy offers a comprehensive book about creating Conda packages for a variety of programming languages and other scenarios. It should serve as a guide book to find your way to solve your own packaging challenges and become a contributor to open source repositories such as conda-forge.

1. Basics
   1. Installation of the tools needed
      1. Windows: MSVC compilers on host system and other settings (DEV mode / long paths)
   3. What is a recipe.yaml file and how to execute it
   4. A simple example recipe
2. Python recipes
   1. A `noarch` recipe
   2. A package with a compiled extension
      1. Variants for multiple Python versions
   3. Cross-compiling a Python package
   4. A Python package with Rust / maturin
3. C & C++ recipes
   1. A simple C program
   2. Cross-compiling a C program
   5. A C++ header only package
   6. A C++ library
      1. When to add run-exports
   7. General rules when building shared libraries
      1. Run-exports
      2. Putting the libraries in `lib/...`
      3. rpath, and debugging rpath
   8. Popular build systems
      1. Autotools
      2. CMake
      3. Meson
   9. Windows
      1. Windows compilers situation (MSVC not being redistributable)
      2. Common problems on Windows (e.g. NOMINMAX)
4. A simple Rust package
   1. Straight forward and demonstrate how to repackage license metadata with cargo-license
5. A simple Go package
   1. Straight forward and demonstrate go-license-collector
6. A R package
   1. A simple `noarch: generic` R package
   2. A R package with a compiled extension
   3. Cross-compiling R packages
7. Zig package
8. Desktop integration
   1. Shell completion generation
   2. Menu items with `menuinst`
9. Complicated packages
   1.  Discuss how compiler packages / cross-compiler packages are built
   2.  Splitting packages and writing multi-output recipes
10. Miscellaneous
   1. Anatomy of a Conda package
   2. What is `stdlib('c')`?
   3. Generating recipes with `rattler-build generate-recipe`
   4. Debugging recipe execution
      1. Entering the "work dir"
      2. Running with `--debug`
      3. Creating patches
   5. Writing tests for recipes