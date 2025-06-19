# Packaging Go Applications

This tutorial covers packaging Go applications for conda-forge, using `cobra-cli` as an example, and demonstrates go-license-detector for license compliance.

## Why Package Go Applications?

Go applications are excellent for conda packaging:

- **Single binary**: Statically linked, no runtime dependencies
- **Fast compilation**: Quick builds across platforms  
- **Cross-platform**: Excellent Windows, macOS, Linux support
- **Static linking**: Self-contained binaries
- **Growing ecosystem**: Many useful CLI tools and servers

## The `go` compiler

The conda-forge ecosystem provides two distinct Go compiler packages to accommodate different development needs: `go-nocgo` and `go-cgo`. The key difference lies in their CGO (C Go) support - CGO is Go's foreign function interface that allows Go programs to call C code and vice versa. The `go-nocgo` compiler, which serves as the default "go" package in conda-forge, is built without CGO support. This means it produces pure Go binaries that don't depend on system C libraries, making them more portable and easier to distribute across different systems.

The `go-cgo` compiler, on the other hand, includes full CGO support, enabling developers to build Go applications that need to interface with C libraries or use Go packages that have C dependencies. While `go-cgo` provides more flexibility for complex integrations, it comes with trade-offs: the resulting binaries are platform-specific and require careful management of C library dependencies. 

Of course we can use Conda to manage the C dependencies as well - so both compilers work extremely well for distributing Go packages in the Conda ecosystem.

### Cross-compilation with Go

The Go compilers from conda-forge will automatically enable cross-compilation (thanks to the `${{ compiler('go-nocgo') }}` magic).

Cross-compilation in Go works by setting environment variables, which is done by the _activation scripts_ of the Go compilers:

```sh
export CGO_ENABLED=${CGO_ENABLED}
export GOOS=${GOOS}
export GOARCH=${GOARCH}
export CONDA_GO_COMPILER=1
```

For example, for `osx-64`, the `GOOS` would be set to `darwin`, and `GOARCH` to `amd64`. Similarly, for `linux-aarch64`, it would be `linux` and `arm64`.

The source for these scripts [can be found on Github](https://github.com/conda-forge/go-feedstock/blob/main/recipe/compiler/activate.sh).

## Go License Challenges

Go packages usually have many dependencies, and they are linked statically. Each dependency comes with it's own license, and since they are linked statically, we should ship the license for compliance purposes.

Luckily there is [the `go-licenses` tool](https://github.com/google/go-licenses) that will bundle all licenses into a folder that we can easily ship with the package.

During the build process, we usually run `go-licenses save ...` to collect all licenses in a single place and include them in the package:

```yaml
requirements:
  build:
    - go-licenses

build:
  script:
    - go-licenses save ./cmd/temporal --save_path $SRC_DIR/library_licenses

about:
  license_file:
    - library_licenses/
```
