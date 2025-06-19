# Building Go Packages with Conda: A Complete Guide

This guide demonstrates how to create Conda packages for Go applications using ```rattler-build```. We'll use the Temporal CLI recipe as a comprehensive example that showcases various techniques for packaging Go software.

## Understanding the Recipe Structure

Let's examine a complete Go package recipe with detailed annotations:

```yaml
context:
  version: "1.3.0"  # (1)!

package:
  name: temporalio-cli
  version: ${{ version }}  # (2)!

source:
  url: https://github.com/temporalio/cli/archive/refs/tags/v${{ version }}.tar.gz
  sha256: 15be9f155cd5114367942568f884969f7ed2d3262ad39bb665cf359735f643b3
  target_directory: src  # (3)!

build:
  number: 0
  script:
    - cd src
    # (4)!
    - go-licenses save ./cmd/temporal --save_path ../library_licenses \
        --ignore github.com/cactus/go-statsd-client/statsd \
        --ignore modernc.org/mathutil  
    - if: win  # (5)!
      then: go build -ldflags="-s -w -X github.com/temporalio/cli/temporalcli.Version=${{ version }}" -v -o %LIBRARY_BIN%\temporal.exe ./cmd/temporal
      else: go build -ldflags="-s -w -X github.com/temporalio/cli/temporalcli.Version=${{ version }}" -v -o $PREFIX/bin/temporal ./cmd/temporal
    - if: unix  # (6)!
      then:
        - mkdir -p $PREFIX/share/bash-completion/completions
        - temporal completion bash > $PREFIX/share/bash-completion/completions/temporal
        - mkdir -p $PREFIX/share/zsh/site-functions
        - temporal completion zsh > $PREFIX/share/zsh/site-functions/_temporal
        - mkdir -p $PREFIX/share/fish/vendor_completions.d
        - temporal completion fish > $PREFIX/share/fish/vendor_completions.d/temporal.fish

requirements:
  build:
    - ${{ stdlib("c") }}  # (7)!
    - ${{ compiler('go-nocgo') }}  # (8)!
    - go-licenses  # (9)!

tests:
  - script:
      - temporal --version  # (10)!

about:
  homepage: https://temporal.io/
  license: MIT
  license_file:
    - LICENSE
    - library_licenses/  # (11)!
    # these two are not properly collected by go-licenses
    - go-statsd-client.txt
    - mathutil-license.txt

  summary: Command-line interface for running and interacting with Temporal Server and UI
  description: |
    Temporal CLI is a command-line interface for running and interacting with Temporal Server and UI.
  repository: https://github.com/temporalio/cli
  documentation: https://docs.temporal.io/cli

extra:
  recipe-maintainers:
    - wolfv
```

1. **Context variables**: Define reusable values that can be referenced throughout the recipe using ```${{ variable }}``` syntax. This promotes DRY (Don't Repeat Yourself) principles.

2. **Variable interpolation**: The version defined in context is used here, ensuring consistency across the recipe.

3. **Target directory**: Extracts the source archive into a subdirectory named ```src```. This is useful when the build process needs to operate outside the source tree.

4. **License collection**: ```go-licenses``` is a critical tool for Go packages. It:

     - Scans all dependencies and collects their licenses
     - Saves them to a directory that will be included in the package
     - Can ignore specific packages that cause issues
     - Ensures legal compliance for all vendored dependencies

6. **Cross-platform builds**: The ```if/then/else``` construct handles platform-specific build commands:

     - Windows: Uses ```%LIBRARY_BIN%``` and adds ```.exe``` extension
     - Unix: Uses ```$PREFIX/bin``` for the binary location
     - The ```-ldflags``` inject version information and strip debug symbols (```-s -w```)

7. **Shell completions**: Modern CLI tools should provide shell completions. This section:

     - Creates appropriate directories for each shell type
     - Generates completion files using the built binary
     - Places them in standard locations where shells expect to find them

9. **C standard library**: Even pure Go programs may need the C stdlib for certain operations. The ```stdlib()``` function ensures the correct version for the target platform.

10. **Go compiler**: The ```go-nocgo``` variant is used when CGO is not needed, resulting in:

     - Faster builds
     - Better cross-platform compatibility
     - Statically linked binaries

12. **Build tools**: Additional tools needed during the build process but not at runtime.

13. **Testing**: A simple smoke test ensures the binary was built correctly and can execute.

14. **License files**: All collected licenses must be included in the package. The directory path ensures all dependency licenses are distributed with the binary.

## Key Concepts for Go Packaging

### 1. Static vs Dynamic Linking

Go typically produces statically linked binaries, but when using CGO, dynamic linking may occur. Choose the appropriate compiler:

```yaml
# For pure Go (recommended when possible)
- ${{ compiler('go-nocgo') }}

# When CGO is required
- ${{ compiler('go') }}
- ${{ compiler('c') }}  # Also needed for CGO
```

### 2. Build Flags Best Practices

Common ldflags for production builds:

```bash
-ldflags="-s -w -X main.version=${{ version }}"
```

- ```-s```: Strip symbol table
- ```-w```: Strip debug information
- ```-X```: Set variables at link time (useful for version injection)

#### Finding upstream build flags

To find variables available to configure, we can take a look at the [`.goreleaser.yml` in the upstream repository](https://github.com/temporalio/cli/blob/main/.goreleaser.yml):

```yaml
...
      ldflags:
        - -s -w -X github.com/temporalio/cli/temporalcli.Version={{.Version}}
```

Using similar `ldflags` is always a reasonable choice!

Alternatively, sometimes the upstream Makefile might contain LDFLAGS, e.g.:

```
VERSION := $(shell git describe --tags --always)
LDFLAGS := -X 'github.com/org/project/cmd.Version=$(VERSION)' \
           -X 'github.com/org/project/cmd.BuildTime=$(shell date -u +%Y-%m-%dT%H:%M:%SZ)' \
           -X 'github.com/org/project/cmd.GitCommit=$(shell git rev-parse HEAD)'
```

### 3. Module Proxy Configuration

For private repositories or when behind a firewall:

```yaml
build:
  script:
    - export GOPROXY=https://proxy.golang.org,direct
    - export GOPRIVATE=github.com/mycompany/*
    - go build ./cmd/myapp
```

## Common Patterns and Solutions

### Handling Multiple Binaries

```yaml
build:
  script:
    - for cmd in cmd/*; do
        go build -o $PREFIX/bin/$(basename $cmd) ./$cmd
      done
```

### Including Additional Resources

```yaml
build:
  script:
    - go build -o $PREFIX/bin/myapp ./cmd/myapp
    - cp -r templates $PREFIX/share/myapp/
    - cp config.yaml $PREFIX/etc/myapp/
```

### Post-Build Verification

```yaml
tests:
  - script:
      - myapp --version
      - myapp --help
  - commands:
      - test -f $PREFIX/share/bash-completion/completions/myapp
  - imports:  # For packages that provide Go libraries
      - github.com/org/project/pkg/api
```

## Troubleshooting Tips

1. **Missing dependencies**: Use ```go mod download``` before building
2. **License collection failures**: Some packages may need to be ignored in ```go-licenses```
3. **CGO issues**: Ensure all C dependencies are listed in requirements
4. **Version injection**: Use ```-X``` ldflags to embed version information

By following these patterns, you can create robust, cross-platform Conda packages for Go applications that integrate seamlessly with the broader Conda ecosystem.

