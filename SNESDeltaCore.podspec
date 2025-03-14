Pod::Spec.new do |spec|
  spec.name         = "SNESDeltaCore"
  spec.version      = "0.1"
  spec.summary      = "Super Nintendo Entertainment System plug-in for Delta emulator."
  spec.description  = "iOS framework that wraps Snes9x to allow playing SNES games with Delta emulator."
  spec.homepage     = "https://github.com/rileytestut/SNESDeltaCore"
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/rileytestut/SNESDeltaCore.git" }

  spec.author             = { "Riley Testut" => "riley@rileytestut.com" }
  spec.social_media_url   = "https://twitter.com/rileytestut"
  
  spec.source_files  = "SNESDeltaCore/**/*.{h,m,mm,swift}", "snes9x/*.{h,hpp}", "snes9x/apu/*.{h,hpp}"
  spec.public_header_files = "SNESDeltaCore/Types/SNESTypes.h", "SNESDeltaCore/Bridge/SNESEmulatorBridge.h"
  spec.header_mappings_dir = ""
  spec.resource_bundles = {
    "SNESDeltaCore" => ["SNESDeltaCore/**/*.deltamapping", "SNESDeltaCore/**/*.deltaskin"]
  }
  
  spec.dependency 'DeltaCore'
    
  spec.xcconfig = {
    "HEADER_SEARCH_PATHS" => '"${PODS_CONFIGURATION_BUILD_DIR}"',
    "USER_HEADER_SEARCH_PATHS" => '"${PODS_CONFIGURATION_BUILD_DIR}/DeltaCore/Swift Compatibility Header" "$(PODS_ROOT)/Headers/Private/SNESDeltaCore/snes9x"',
    "OTHER_CFLAGS" => "-funsigned-char -ffast-math -finline -fno-builtin -fno-common -fomit-frame-pointer -funroll-loops -fstrict-aliasing -DHAVE_STDINT_H -DARM -DSTATIC_LIBRARY=1"
  }
  
end
