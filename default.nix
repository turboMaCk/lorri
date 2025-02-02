{
  pkgs ? import ./nix/nixpkgs.nix { },
  src ? pkgs.nix-gitignore.gitignoreSource [".git/"] ./.
}:
pkgs.rustPlatform.buildRustPackage rec {
  name = "lorri";

  inherit src;

  BUILD_REV_COUNT = src.revCount or 1;
  RUN_TIME_CLOSURE = pkgs.callPackage ./nix/runtime.nix {};

  cargoSha256 = "094w2lp6jvxs8j59cjqp6b3kg4y4crlnqka5v2wmq4j0mn6hvhsj";

  NIX_PATH = "nixpkgs=${./nix/bogus-nixpkgs}";

  USER = "bogus";

  nativeBuildInputs = [ ];
  buildInputs = [ pkgs.nix pkgs.direnv pkgs.which ] ++
    pkgs.stdenv.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.darwin.cf-private
      pkgs.darwin.Security
      pkgs.darwin.apple_sdk.frameworks.CoreServices
    ];

  preConfigure = ''
    . ${./nix/pre-check.sh}

    # Do an immediate, light-weight test to ensure logged-evaluation
    # is valid, prior to doing expensive compilations.
    nix-build --show-trace ./src/logged-evaluation.nix \
      --arg src ./tests/integration/basic/shell.nix \
      --arg runTimeClosure "$RUN_TIME_CLOSURE" \
      --no-out-link
  '';

  # Darwin fails to build doctests with:
  # dyld: Symbol not found __ZTIN4llvm2cl18GenericOptionValueE
  # see: https://github.com/NixOS/nixpkgs/pull/49839
  doCheck = !pkgs.stdenv.isDarwin;
}
