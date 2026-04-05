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
  libtiff,
  libxcb-cursor,
  libxcb-wm,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  qt6,
  gtk3,
  pango,
  atk,
  cairo,
  gdk-pixbuf,
  autoStart ? false,
}:

stdenv.mkDerivation rec {
  pname = "freedownloadmanager";
  version = "6.33.2";

  src = fetchurl {
    url = "https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
    hash = "sha256-n1Y6h9xXeqU6LO6h66qlnT9wsjFYqToaAPJ8sTYL9Gg=";
  };

  unpackPhase = "dpkg-deb -x $src .";

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    qt6.wrapQtAppsHook
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
    qt6.qtbase
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

  autoPatchelfIgnoreMissingDeps = [
    "libclntsh.so.23.1"
    "libmimerapi.so"
    "libfbclient.so.2"
  ];

  preFixup = ''
    qtWrapperArgs+=(
      --prefix QT_PLUGIN_PATH : "$out/freedownloadmanager/plugins"
      --prefix QML2_IMPORT_PATH : "$out/freedownloadmanager/qml"
    )
  '';

  installPhase = ''
    # Create required directories
    mkdir -p $out/bin
    mkdir -p $out/share/applications

    # Copy files from the unpacked deb
    cp -r opt/freedownloadmanager $out
    cp -r usr/share $out

    # Symlink binary
    ln -s $out/freedownloadmanager/fdm $out/bin/${pname}

    # Fix the desktop file pathing and icons
    substituteInPlace $out/share/applications/freedownloadmanager.desktop \
      --replace-fail 'Exec=/opt/freedownloadmanager/fdm' 'Exec=${pname}' \
      --replace-fail "Icon=/opt/freedownloadmanager/icon.png" "Icon=$out/freedownloadmanager/icon.png"

    # Handle Autostart if enabled
    ${lib.optionalString autoStart ''
      mkdir -p $out/etc/xdg/autostart
      cp $out/share/applications/freedownloadmanager.desktop $out/etc/xdg/autostart/fdm.desktop
      substituteInPlace $out/etc/xdg/autostart/fdm.desktop \
        --replace-fail 'Exec=${pname}' 'Exec=${pname} --hidden'
    ''}

    # Fix libtiff versioning
    ln -s ${lib.getLib libtiff}/lib/libtiff.so $out/freedownloadmanager/lib/libtiff.so.5
  '';

  meta = with lib; {
    description = "A smart and fast internet download manager";
    homepage = "https://www.freedownloadmanager.org";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
