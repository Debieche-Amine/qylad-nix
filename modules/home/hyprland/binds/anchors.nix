{
  lib,
  modifier,
}: let
  anchors = [
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
in
  lib.concatMap (anchor: [
    "${modifier}, ${anchor.key}, workspace, name:${anchor.workspace}"
    "${modifier} SHIFT, ${anchor.key}, movetoworkspace, name:${anchor.workspace}"
  ])
  anchors
