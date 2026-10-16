{
  lib,
  modifier,
}: let
  letterAnchors = [
    {
      key = "A";
      workspace = "A:0";
    }
    {
      key = "Z";
      workspace = "Z:0";
    }
    {
      key = "E";
      workspace = "E:0";
    }
    {
      key = "Y";
      workspace = "Y:0";
    }
    {
      key = "U";
      workspace = "U:0";
    }
    {
      key = "I";
      workspace = "I:0";
    }
    {
      key = "O";
      workspace = "O:0";
    }
    {
      key = "P";
      workspace = "P:0";
    }
  ];

  # AZERTY number row anchors: binds both unshifted symbol and shifted digit
  numberAnchors = [
    {
      symbol = "egrave";
      digit = "7";
      workspace = "7:0";
    }
    {
      symbol = "underscore";
      digit = "8";
      workspace = "8:0";
    }
    {
      symbol = "ccedilla";
      digit = "9";
      workspace = "9:0";
    }
    {
      symbol = "agrave";
      digit = "0";
      workspace = "0:0";
    }
  ];
in
  (lib.concatMap (anchor: [
      "${modifier}, ${anchor.key}, workspace, name:${anchor.workspace}"
      "${modifier} SHIFT, ${anchor.key}, movetoworkspace, name:${anchor.workspace}"
    ])
    letterAnchors)
  ++ (lib.concatMap (anchor: [
      "${modifier}, ${anchor.symbol}, workspace, name:${anchor.workspace}"
      "${modifier}, ${anchor.digit}, workspace, name:${anchor.workspace}"
      "${modifier} SHIFT, ${anchor.symbol}, movetoworkspace, name:${anchor.workspace}"
      "${modifier} SHIFT, ${anchor.digit}, movetoworkspace, name:${anchor.workspace}"
    ])
    numberAnchors)
