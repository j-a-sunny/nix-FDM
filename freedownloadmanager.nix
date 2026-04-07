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
    url = "http://debrepo.freedownloadmanager.org/pool/main/f/freedownloadmanager/freedownloadmanager_6.33.2.6656_amd64.deb";
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
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    cp -r opt/freedownloadmanager $out
    cp -r usr/share $out
    ln -s $out/freedownloadmanager/fdm $out/bin/${pname}

    ln -s ${lib.getLib libtiff}/lib/libtiff.so $out/freedownloadmanager/lib/libtiff.so.5

    substituteInPlace $out/share/applications/freedownloadmanager.desktop \
      --replace-fail 'Exec=/opt/freedownloadmanager/fdm' 'Exec=${pname}' \
      --replace-warn "Icon=/opt/freedownloadmanager/icon.png" "Icon=$out/freedownloadmanager/icon.png"

    ${lib.optionalString autoStart ''
      mkdir -p $out/etc/xdg/autostart
      cp $out/share/applications/freedownloadmanager.desktop $out/etc/xdg/autostart/fdm.desktop
      substituteInPlace $out/etc/xdg/autostart/fdm.desktop \
        --replace-fail 'Exec=${pname}' 'Exec=${pname} --hidden'
    ''}
  '';
  meta = with lib; {
    description = "A smart and fast internet download manager";
    homepage = "https://www.freedownloadmanager.org";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
