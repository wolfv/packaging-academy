# Installation

To build packages for the Conda ecosystem, we need a recipe execution tool. 
In this tutorial we are going to use `rattler-build`. To install rattler-build, we recommend `pixi`.

First, install `pixi`:

macOS / Linux: `curl -fsSL https://pixi.sh/install.sh | sh`
Windows: `powershell -ExecutionPolicy ByPass -c "irm -useb https://pixi.sh/install.ps1 | iex"`

You can find more installation options in the `pixi` documentation: https://pixi.sh/

Now we can install rattler-build:

```
pixi global install rattler-build
```

You can also use other package managers, such as `brew` or `conda` to install `rattler-build`:

```
brew install rattler-build
# or
conda install rattler-build
```

## Verifying that it works

To validate our installation, we can run

```
$ rattler-build --version
rattler-build 0.43.0
```

Now, everything should be ready to execute our first recipes and build some packages!