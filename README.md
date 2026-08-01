# hbmartin Homebrew Tap

Homebrew formulae maintained by [Harold Martin](https://github.com/hbmartin).

## Install libfreenect2-metal

```sh
brew install hbmartin/tap/libfreenect2-metal
```

The formula installs the libfreenect2 shared library, public headers,
pkg-config metadata, and CMake package metadata. It provides the CPU and Metal
depth-processing pipelines and uses TurboJPEG for RGB decoding. A Kinect is
not required to install or test the package.

To build the current development branch instead of the pinned 0.3.0 source:

```sh
brew install --HEAD hbmartin/tap/libfreenect2-metal
```

Source builds require full Xcode because the Metal shader is compiled during
the build. Published Homebrew bottles contain the compiled shader and do not
need Xcode at installation time.

## Maintainer commands

```sh
brew install --build-from-source hbmartin/tap/libfreenect2-metal
brew test hbmartin/tap/libfreenect2-metal
brew audit --strict --online hbmartin/tap/libfreenect2-metal
brew style hbmartin/tap/libfreenect2-metal
```

Pull requests run Homebrew's `test-bot` workflow on Apple Silicon, Intel macOS,
and Linux syntax-check infrastructure. After a pull request is green, run the
`brew pr-pull` workflow with its pull-request number and reviewed head SHA to
publish its bottles.
