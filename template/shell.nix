{ pkgs ? import <nixpkgs> {} }:
let
  jdkWithFX = pkgs.openjdk.override {
    enableJavaFX = true; # for JavaFX
    # include following line if JavaFX with Webkit is needed
    # openjfx_jdk = pkgs.openjfx.override { withWebKit = true; };
  };
in

pkgs.mkShell {
  buildInputs = [
    jdkWithFX
    pkgs.maven
  ];
}
