class Libfreenect2Metal < Formula
  desc "Kinect v2 driver with Metal-accelerated depth processing"
  homepage "https://hbmartin.github.io/libfreenect2-metal/"
  url "https://github.com/hbmartin/libfreenect2-metal/archive/95f5042e014339b99e2b0ed16abc3b43a07a8464.tar.gz"
  version "0.3.0"
  sha256 "b23d6a89aedaf2af47bceb27d4dca8d7d7e09a6186ce97ed02a3a1ed00d13e54"
  license any_of: ["Apache-2.0", "GPL-2.0-only"]
  head "https://github.com/hbmartin/libfreenect2-metal.git", branch: "master"

  livecheck do
    skip "No tagged release has been published"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on xcode: :build
  depends_on "jpeg-turbo"
  depends_on "libusb"
  depends_on :macos

  def install
    # The pinned snapshot exposes private implementation libraries through its
    # shared CMake target. Keep downstream consumers independent of exact
    # Homebrew Cellar dependency versions. This is fixed in post-snapshot
    # upstream sources and can be removed after the next tagged release.
    config_template = buildpath/"freenect2.cmake.in"
    if config_template.read.include?('INTERFACE_LINK_LIBRARIES "@LIBRARIES@"')
      inreplace config_template,
                'INTERFACE_LINK_LIBRARIES "@LIBRARIES@"',
                'INTERFACE_LINK_LIBRARIES ""'
    end

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

    # The pinned snapshot ships these files but does not install them itself.
    license_dir = share/"doc/libfreenect2"
    license_dir.install "APACHE20", "GPL2", "CONTRIB" unless (license_dir/"APACHE20").exist?
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
