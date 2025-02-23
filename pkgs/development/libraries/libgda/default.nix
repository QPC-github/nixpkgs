{ lib
, stdenv
, fetchurl
, pkg-config
, intltool
, itstool
, libxml2
, gtk3
, openssl
, gnome
, gobject-introspection
, vala
, libgee
, overrideCC
, gcc6
, fetchpatch
, autoreconfHook
, gtk-doc
, autoconf-archive
, yelp-tools
, mysqlSupport ? false
, libmysqlclient ? null
, postgresSupport ? false
, postgresql ? null
}:

assert mysqlSupport -> libmysqlclient != null;
assert postgresSupport -> postgresql != null;

(if stdenv.isAarch64 then overrideCC stdenv gcc6 else stdenv).mkDerivation rec {
  pname = "libgda";
  version = "5.2.10";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "1j1l4dwjgw6w4d1v4bl5a4kwyj7bcih8mj700ywm7xakh1xxyv3g";
  };

  patches = [
    # fix compile error with mysql
    (fetchpatch {
      url = "https://gitlab.gnome.org/GNOME/libgda/-/commit/9859479884fad5f39e6c37e8995e57c28b11b1b9.diff";
      sha256 = "158sncc5bg9lkri1wb0i1ri1nhx4c34rzi47gbfkwphlp7qd4qqv";
    })
  ];

  nativeBuildInputs = [
    pkg-config
    intltool
    itstool
    libxml2
    gobject-introspection
    vala
    autoreconfHook
    gtk-doc
    autoconf-archive
    yelp-tools
  ];

  buildInputs = [
    gtk3
    openssl
    libgee
  ] ++ lib.optionals mysqlSupport [
    libmysqlclient
  ] ++ lib.optionals postgresSupport [
    postgresql
  ];

  configureFlags = [
    "--with-mysql=${if mysqlSupport then "yes" else "no"}"
    "--with-postgres=${if postgresSupport then "yes" else "no"}"

    # macOS builds use the sqlite source code that comes with libgda,
    # as opposed to using the system or brewed sqlite3, which is not supported on macOS,
    # as mentioned in https://github.com/GNOME/libgda/blob/95eeca4b0470f347c645a27f714c62aa6e59f820/libgda/sqlite/README#L31,
    # which references the paper https://web.archive.org/web/20100610151539/http://lattice.umiacs.umd.edu/files/functions_tr.pdf
    # See also https://github.com/Homebrew/homebrew-core/blob/104f9ecd02854a82372b64d63d41356555378a52/Formula/libgda.rb
    "--enable-system-sqlite=${if stdenv.isDarwin then "no" else "yes"}"
  ];

  enableParallelBuilding = true;

  hardeningDisable = [ "format" ];

  passthru = {
    updateScript = gnome.updateScript {
      packageName = pname;
      versionPolicy = "odd-unstable";
      freeze = true;
    };
  };

  meta = with lib; {
    description = "Database access library";
    homepage = "https://www.gnome-db.org/";
    license = with licenses; [
      # library
      lgpl2Plus
      # CLI tools
      gpl2Plus
    ];
    maintainers = teams.gnome.members;
    platforms = platforms.unix;
  };
}
