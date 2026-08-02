class Libfreenect2Metal < Formula
  desc "Kinect v2 driver with Metal-accelerated depth processing"
  homepage "https://hbmartin.github.io/libfreenect2-metal/"
  url "https://github.com/hbmartin/libfreenect2-metal/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "c182a3fbcd35f928b4959069ff44d93d8de4bc7d4ef6d4d32f5f365710c9d7a6"
  license any_of: ["Apache-2.0", "GPL-2.0-only"]
  revision 1
  head "https://github.com/hbmartin/libfreenect2-metal.git", branch: "master"

  bottle do
    root_url "https://github.com/hbmartin/homebrew-tap/releases/download/libfreenect2-metal-0.3.0_1"
    sha256 cellar: :any, arm64_tahoe: "34ca5dd21f6d836e0a39f87b3e69e4531c2d440f862f89bd1e20bf5f28496f60"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on xcode: :build
  depends_on "jpeg-turbo"
  depends_on "libusb"
  depends_on :macos

  def install
    args = %W[
      -DDEPENDS_DIR=false
      -DBUILD_EXAMPLES=OFF
      -DBUILD_OPENNI2_DRIVER=OFF
      -DBUILD_STREAMER_RECORDER=OFF
      -DENABLE_CUDA=OFF
      -DENABLE_METAL=ON
      -DENABLE_OPENCL=OFF
      -DENABLE_OPENGL=OFF
      -DENABLE_TEGRAJPEG=OFF
      -DENABLE_VAAPI=OFF
      -DENABLE_VIDEOTOOLBOX=OFF
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args

    config = (buildpath/"build/libfreenect2/config.h").read
    odie "The Metal pipeline was not compiled; install full Xcode and its Metal toolchain" unless
      config.match?(/^#define LIBFREENECT2_WITH_METAL_SUPPORT\b/)

    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <algorithm>
      #include <iostream>
      #include <string>
      #include <vector>
      #include <libfreenect2/libfreenect2.hpp>

      int main() {
        if (libfreenect2::getVersion() != "0.3.0") {
          return 1;
        }

        const std::vector<std::string> pipelines =
          libfreenect2::getCompiledPacketPipelines();
        if (std::find(pipelines.begin(), pipelines.end(), "cpu") == pipelines.end()) {
          return 2;
        }
        if (std::find(pipelines.begin(), pipelines.end(), "metal") == pipelines.end()) {
          return 3;
        }

        std::cout << libfreenect2::getVersion() << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++11", "test.cpp", "-I#{include}", "-L#{lib}",
                    "-Wl,-rpath,#{lib}", "-lfreenect2", "-o", "test"
    assert_equal "0.3.0", shell_output("./test").strip
  end
end
