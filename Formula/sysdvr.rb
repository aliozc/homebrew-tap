class Sysdvr < Formula
  desc "Stream Switch games to your PC via USB or network"
  homepage "https://github.com/exelix11/SysDVR"
  url "https://github.com/exelix11/SysDVR/releases/download/v6.3/SysDVRClient-MacOs-arm64.zip"
  sha256 "67aa9b3ade49fcf02aab309ccf91d39a2e91e26e430972c093b83daefb1a0fbb"
  license "GPL-2.0-or-later"

  depends_on arch: :arm64
  depends_on :macos

  def install
    libexec.install "SysDVR-Client", "runtimes"
    
    runtime_lib = libexec/"runtimes/osx-arm64/native"
    
    # Map of framework references to actual dylib files
    lib_mappings = {
      "@rpath/SDL2.framework/Versions/A/SDL2" => "SDL2.dylib",
      "@rpath/libavcodec.framework/libavcodec" => "libavcodec.dylib",
      "@rpath/libavdevice.framework/libavdevice" => "libavdevice.dylib",
      "@rpath/libavfilter.framework/libavfilter" => "libavfilter.dylib",
      "@rpath/libavformat.framework/libavformat" => "libavformat.dylib",
      "@rpath/libavutil.framework/libavutil" => "libavutil.dylib",
      "@rpath/libswresample.framework/libswresample" => "libswresample.dylib",
      "@rpath/libswscale.framework/libswscale" => "libswscale.dylib",
    }
    
    # Fix libusb's self-reference
    system "install_name_tool", "-id",
           "#{runtime_lib}/libusb-1.0.dylib",
           "#{runtime_lib}/libusb-1.0.dylib"
    
    # Fix all dylib references
    Dir["#{runtime_lib}/*.dylib"].each do |dylib|
      lib_mappings.each do |old_ref, new_file|
        output = `otool -L "#{dylib}" 2>/dev/null`
        if output.include?(old_ref)
          system "install_name_tool", "-change",
                 old_ref,
                 "#{runtime_lib}/#{new_file}",
                 dylib
        end
      end
    end
    
    # Create wrapper script
    (bin/"SysDVR-Client").write <<~EOS
      #!/bin/bash
      export DYLD_LIBRARY_PATH="#{runtime_lib}:$DYLD_LIBRARY_PATH"
      exec "#{libexec}/SysDVR-Client" "$@"
    EOS
  end

  test do
    assert_predicate bin/"SysDVR-Client", :exist?
    assert_predicate bin/"SysDVR-Client", :executable?
  end
end
