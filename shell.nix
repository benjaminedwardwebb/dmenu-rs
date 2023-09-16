{ pkgs
, package
}:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    rustc
  ] ++ package.nativeBuildInputs
  ++ package.buildInputs;
  RUST_BACKTRACE = 0;
  VERSION = package.version;
}
