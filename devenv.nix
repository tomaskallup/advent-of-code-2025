{ pkgs, ... }:
{
  languages.elixir.enable = true;

  packages = with pkgs; [
    highs
  ];
}
