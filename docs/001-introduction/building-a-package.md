# Building a Conda package

To build a package, we need to write a "recipe". The `recipe` defines everything that makes up the package:

- Dependencies
- Source code
- Build script
- Metadata about the package (name, summary, license, ...)

## Walkthrough example

Example recipe for the Python `rich` library:

```yaml
context:
  version: "13.4.2"

package:
  name: "rich"
  version: ${{ version }}

source:
  - url: https://pypi.io/packages/source/r/rich/rich-${{ version }}.tar.gz
    sha256: d653d6bccede5844304c605d5aac802c7cf9621efd700b46c7ec2b51ea914898

build:
  # Thanks to `noarch: python` this package works on all platforms
  noarch: python
  script:
    - python -m pip install . -vv

requirements:
  host:
    - pip
    - poetry-core >=1.0.0
    - python 3.10.*
  run:
    # sync with normalized deps from poetry-generated setup.py
    - markdown-it-py >=2.2.0
    - pygments >=2.13.0,<3.0.0
    - python 3.10.*
    - typing_extensions >=4.0.0,<5.0.0

tests:
  - package_contents:
      site_packages:
        - rich
  - python:
      imports:
        - rich

about:
  homepage: https://github.com/Textualize/rich
  license: MIT
  license_file: LICENSE
  summary: Render rich text, tables, progress bars, syntax highlighting, markdown and more to the terminal
  description: |
    Rich is a Python library for rich text and beautiful formatting in the terminal.

    The Rich API makes it easy to add color and style to terminal output. Rich
    can also render pretty tables, progress bars, markdown, syntax highlighted
    source code, tracebacks, and more — out of the box.
  documentation: https://rich.readthedocs.io
  repository: https://github.com/Textualize/rich

```

### Context

In the context we set up some variables that we can re-use throughout the package recipe. In this case, we use the `version` as a variable which will make it easy to update the version number from a single place later on (it's used in the package.version and source.url).

```yaml
context:
  version: "13.4.2"
```

### Package object

The package object contains the main metadata: package name and version for the package. Here we use the `${{ version }}` to reuse the variable that we set in the context using Jinja.

```yaml
package:
  name: "rich"
  version: ${{ version }}
```

### Source object

In the source object we have a list of source that we need to fetch to create the package. We usually prefer tarballs from Github or other places and build the package "from scratch" instead of re-packaging already built software.

```yaml
source:
  - url: https://pypi.io/packages/source/r/rich/rich-${{ version }}.tar.gz
    sha256: d653d6bccede5844304c605d5aac802c7cf9621efd700b46c7ec2b51ea914898
```

### Build section

In the build section we set some additional properties. For example, setting `noarch: python` will create a package that works across multiple Python versions and operating systems. 

The `script` is one of the most important keys - it defines the instructions that need to be run in the isolated build environment. This is always 

```yaml
build:
  # Thanks to `noarch: python` this package works on all platforms
  noarch: python
  script:
    - ${{ PYTHON }} -m pip install . -vv
```

The build script can also be an external file like `build.sh` or `build.bat`.

#### How the build actually works

You might have asked yourself what "building the package" actually means and what the job of the build script is. 

In the most simple terms, the package is everything that is new in the `$PREFIX`. The contents of the `$PREFIX` directory are everything that is part of the `host` environment. Any new files will be part of the new package.
For example, if your build script does:

```
echo "foobar" > $PREFIX/foobar.txt
```

Then your package will contain a single file, named `foobar.txt` with the content `foobar`.

When running `pip` from a `python` installation _inside_ the `$PREFIX`, `pip` will automatically install the new files into `$PREFIX/lib/python3.12/site-packages/rich` (for the rich example). As you see, these will be _new files in the $PREFIX_ and thus they will end up in our package.

### The requirements section

```yaml
requirements:
  host:
    - pip
    - poetry-core >=1.0.0
    - python 3.10.*
  run:
    # sync with normalized deps from poetry-generated setup.py
    - markdown-it-py >=2.2.0
    - pygments >=2.13.0,<3.0.0
    - python 3.10.*
    - typing_extensions >=4.0.0,<5.0.0
```

In the requirements section we define the packages that are build, link and run-time dependencies of the software that we are packaging.

We define these requirements as "MatchSpecs" which is a conda-specific format. You can denote version ranges easily, e.g. by using `python 3.10.*` to select any 3.10 version of Python.

### The about section

The about section contains metadata about the package, such as a link to the documentation.

Also, very important – it contains the license as [SPDX](https://spdx.org/licenses/) identifier (a standardized format). 

```yaml
about:
  homepage: https://github.com/Textualize/rich
  license: MIT
  license_file: LICENSE
  summary: Render rich text, tables, progress bars, syntax highlighting, markdown and more to the terminal
  description: |
    Rich is a Python library for rich text and beautiful formatting in the terminal.

    The Rich API makes it easy to add color and style to terminal output. Rich
    can also render pretty tables, progress bars, markdown, syntax highlighted
    source code, tracebacks, and more — out of the box.
  documentation: https://rich.readthedocs.io
  repository: https://github.com/Textualize/rich
```

The `license_file` can point to either a license from the source code repository (as downloaded previously) or to a license file that is part of the recipe folder. Sometimes the repository does not contain the license text, and then we can add it as a file in the recipe.

For conda-forge it's very important to always include the accurate license & license file with the package.

### Actually building the package

We can now actually run `rattler-build` to build the package.

```
rattler-build build --recipe ./rich/recipe.yaml
```

You will see a lot of log output on the terminal that indicates things are happening. What rattler-build does under the hood is the following:

- Read the recipe.yaml file
- Evaluate all the Jinja templates and fill them with values
- Cross-reference the recipe.yaml with the "variants"
- Run the build for each package / package variant in the recipe file
	1. Create isolated build environment
	2. Run the build script
	3. Collect new files
	4. Add metadata about the package (from `about`, `requirements`, ...)
	5. Bundle metadata and files into a tarball

### Generating a recipe for CRAN or PyPI

In order to make it easy to package software that is already available on CRAN or PyPI, rattler-build has a little "recipe-generator" built-in. This tool can provide a useful _starting point_ to build out packages for R or Python.

```sh
rattler-build generate-recipe cran corrplot
```

Generates the following output:

```yaml
context: {}

package:
  name: r-corrplot
  version: '0.95'

source:
- url:
  - https://cran.r-project.org/src/contrib/corrplot_0.95.tar.gz
  - https://cran.r-project.org/src/contrib/Archive/corrplot_0.95.tar.gz
  sha256: 84a31f675041e589201b4d640753302abc10ccc2c0ca0a409b5153861989d776

build:
  script: R CMD INSTALL --build .

requirements:
  host:
  - r-base
  - r-base >=4.1.0
  run:
  - r-base
  # -  r-seriation  # suggested
  # -  r-knitr  # suggested
  # -  r-rcolorbrewer  # suggested
  # -  r-rmarkdown  # suggested
  # -  r-magrittr  # suggested
  # -  r-prettydoc  # suggested
  # -  r-testthat  # suggested

tests:
- script:
  - Rscript -e 'library("corrplot")'

about:
  homepage: https://github.com/taiyun/corrplot
  summary: Visualization of a Correlation Matrix
  description: |-
    Provides a visual exploratory tool on correlation matrix
    that supports automatic variable reordering to help detect
    hidden patterns among variables.
  license: MIT
  license_file: LICENSE
  repository: https://github.com/cran/corrplot
```

As you can see, some of the requirements are commented and marked. These are _suggested_ requirements from CRAN which is not something that easily maps to conda packages today. We (at prefix) are working on adding conditional and optional dependency sets to the Conda spec so - hopefully - we can also easily support these `suggested` packages soon!


### Contributing a package to conda-forge

Now you might want to contribute a package to conda-forge. This could be your own software or someone else's software. Contributing software to conda-forge can be a fun experience.

Once you have your recipe in a good working shape, the process to add a package to conda-forge is as follows:

1. Submit the package to the [staged-recipes](https://github.com/conda-forge/staged-recipes/) repository on Github
2. Make sure that the CI is green on all platforms that you want to support (osx-64, linux-64, win-64 are tested on staged recipes, but you can "skip" the ones that are not supported by the software)
3. Get a review of your recipe (sometimes this takes time – you can ping the conda-forge maintainers on [Zulip](https://conda-forge.zulipchat.com/))
4. Once your recipe is merged, a new _feedstock_ will be created. The _feedstock_ is a Git repository on Github that contains your recipe + CI scripts to build the package whenever the recipe is updated.
5. The autotick-bot will come around whenever a new version is available "upstream" and automatically update the version of your recipe.
6. When the new version is green as well, you can merge the updates in your feedstock and a new version of your package will be published and available.

When you add your recipe to staged-recipes, it's important to add an extra field:

```yaml
# ...

extra:
  recipe-maintainers:
    - wolfv
    - rubenarts
    - ... github handles of other collaborators
```

Everyone mentioned under `recipe-maintainers` will get access to the feedstock, and will be able to push to the recipe once created.

Additionally, the conda-forge core team also has access to all feedstocks and can help move things along if things are stuck for whatever reason.

There is much more documentation on the whole process on the [conda-forge website](https://conda-forge.org/docs/maintainer/adding_pkgs/).

### Building a package with a compiler

Packages that contain compiled code are a bit different from "noarch" packages. Compiled code is specific to an operating system and even specific to a CPU architecture – `noarch` cannot be used! 

There can be pure C, C++, Rust or Go packages that contain compiled code and use build tools such as CMake, Meson, Autotools, Cargo or Make. But also Python and R packages can contain compiled extensions that are written in C or other languages, and compiled by the `setup.py` code.

There are a few extra rules when building a compiled package:

- Use the `${{ compiler(...) }}` Jinja magic to enable cross-compilation (for example, from linux-64 to linux-aarch64)
- Use `requirements.build` for build tools that need to be executed at build time, such as CMake, Make, the compilers, ...
- Use the `requirements.host` section for libraries that need to be _linked_ as shared libraries. These will be in the target architecture when cross-compiling (e.g. `linux-aarch64` in the example above) and cannot be executed at build time.

#### Example recipe for `curl`

Building `curl` uses the C compiler from conda-forge, as well as `autotools` on Linux and macOS and CMake on Windows.

```yaml
context:
  version: "8.0.1"

package:
  name: curl
  version: ${{ version }}

source:
  url: http://curl.haxx.se/download/curl-${{ version }}.tar.bz2
  sha256: 9b6b1e96b748d04b968786b6bdf407aa5c75ab53a3d37c1c8c81cdb736555ccf

build:
  number: 0

requirements:
  build:
    - ${{ compiler('c') }}
    - if: win
      then:
        - cmake
        - ninja
    - if: unix
      then:
        - make
        - perl
        - pkg-config
        - libtool
  host:
    - if: linux
      then:
        - openssl
    - zlib

tests:
  - script:
      - curl --version

about:
  homepage: http://curl.haxx.se/
  license: curl
  license_file: COPYING
  summary: tool and library for transferring data with URL syntax
  description: |
    Curl is an open source command line tool and library for transferring data
    with URL syntax. It is used in command lines or scripts to transfer data.
  documentation: https://curl.haxx.se/docs/
  repository: https://github.com/curl/curl
```

And next to this, the `build.sh` and `build.bat` files for Unix and Windows:

```sh
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

if [[ $target_platform =~ linux.* ]]; then
    USESSL="--with-openssl=${PREFIX}"
else
    USESSL="--with-secure-transport"
fi;

./configure \
    --prefix=${PREFIX} \
    --host=${HOST} \
    ${USESSL} \
    --with-ca-bundle=${PREFIX}/ssl/cacert.pem \
    --disable-static --enable-shared

make -j${CPU_COUNT}
make install

# Includes man pages and other miscellaneous.
rm -rf "${PREFIX}/share"
```

```
mkdir build

cmake -GNinja ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DBUILD_SHARED_LIBS=ON ^
      -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
      -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
      -DCURL_USE_SCHANNEL=ON ^
      -DCURL_USE_LIBSSH2=OFF ^
      -DUSE_ZLIB=ON ^
      -DENABLE_UNICODE=ON ^
      %SRC_DIR%

IF %ERRORLEVEL% NEQ 0 exit 1

ninja install --verbose
```

### Advanced topics for package building

- When you build shared libraries into packages, you would want to learn about [`run-exports`](https://rattler.build/latest/reference/recipe_file/#run-exports)
- Virtual packages to specify system compatibility (e.g. __osx >=10.15)
- Multi-output packages with the `outputs` key to split a package build into multiple pieces

### Future of package building

We are working on `pixi build` which directly integrates the package building into the pixi package manager. It will be possible to depend on other pixi projects from source, or build a pixi project into a conda package for distribution without having to invoke `rattler-build` or write a recipe.
