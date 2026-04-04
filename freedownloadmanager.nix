{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  udev,
  libdrm,
  libpqxx,
  unixodbc,
  gst_all_1,
  libpulseaudio,
  mysql80,
  # --- NEW ARGUMENTS ---
  libtiff, # Replaces the generic libtiff to handle specific .so versions
  libxcb-cursor, # Required for Qt6 cursor support
  libxcb-wm, # Moved out of 'xorg' scope to top-level for better visibility
  libxcb-image, # Same as above
  libxcb-keysyms, # Same as above
  libxcb-render-util, # Same as above
  qt6, # Added to provide the Qt6 wrapping infrastructure [cite: 10]
  gtk3, # Added to satisfy the GTK3 platform theme plugin
  pango, # Text rendering dependency for the GTK3 plugin
  atk, # Accessibility dependency for the GTK3 plugin
  cairo, # Vector graphics dependency for the GTK3 plugin
  gdk-pixbuf, # Image loading dependency for the GTK3 plugin
}:

stdenv.mkDerivation rec {
  pname = "freedownloadmanager";
  version = "6.33.2"; # Updated to the latest available version [cite: 11]

  src = fetchurl {
    url = "https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
    hash = "sha256-n1Y6h9xXeqU6LO6h66qlnT9wsjFYqToaAPJ8sTYL9Gg=";
  };

  unpackPhase = "dpkg-deb -x $src ."; # [cite: 12]

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    qt6.wrapQtAppsHook # REPLACED wrapGAppsHook; essential for wrapping Qt6 apps [cite: 12]
  ];

  buildInputs = [
    libdrm
    libpqxx
    unixodbc
    stdenv.cc.cc
    mysql80
    libtiff
    libxcb-cursor
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libpulseaudio
    qt6.qtbase # Added to ensure core Qt6 libraries are available [cite: 13]
    gtk3
    pango
    atk
    cairo
    gdk-pixbuf
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-libav
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);

  # Tells autoPatchelf to ignore database drivers that aren't available in Nixpkgs
  # This prevents the build from failing on non-essential missing libraries [cite: 15]
  autoPatchelfIgnoreMissingDeps = [
    "libclntsh.so.23.1"
    "libmimerapi.so"
    "libfbclient.so.2"
  ];

  # --- CRITICAL FIX FOR RUNTIME CRASHES ---
  # This section creates a 'wrapper' around the app that sets environment variables.
  # Without this, the app can't find its own UI plugins and will Segfault/Abort.
  preFixup = ''
    qtWrapperArgs+=(
      --prefix QT_PLUGIN_PATH : "$out/freedownloadmanager/plugins"
      --prefix QML2_IMPORT_PATH : "$out/freedownloadmanager/qml"
    )
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r opt/freedownloadmanager $out
    cp -r usr/share $out

    # Create the main executable symlink in the system path 
    ln -s $out/freedownloadmanager/fdm $out/bin/${pname}

    # FIX FOR libtiff.so.5:
    # FDM expects version 5, but Nixpkgs usually provides version 6. 
    # We link the newer version to the name FDM expects. 
    ln -s ${lib.getLib libtiff}/lib/libtiff.so $out/freedownloadmanager/lib/libtiff.so.5

    # Ensure the desktop shortcut calls our 'wrapped' binary and finds its icon 
    substituteInPlace $out/share/applications/freedownloadmanager.desktop \
      --replace 'Exec=/opt/freedownloadmanager/fdm' 'Exec=${pname}' \
      --replace "Icon=/opt/freedownloadmanager/icon.png" "Icon=$out/freedownloadmanager/icon.png"
  '';

  meta = with lib; {
    description = "A smart and fast internet download manager";
    homepage = "https://www.freedownloadmanager.org";
    license = licenses.unfree; # [cite: 19]
    platforms = [ "x86_64-linux" ];
  };
}
