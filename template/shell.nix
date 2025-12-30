{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.javaPackages.compiler.temurin-bin.jdk-21
    pkgs.maven
  ];
}
