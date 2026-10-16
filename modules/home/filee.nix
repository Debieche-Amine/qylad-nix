{pkgs, ...}: let
  filee = pkgs.callPackage ../../pkgs/filee {};
in {
  home.packages = [
    filee
  ];

  # Declarative Thunar Custom Actions (uca.xml)
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Open Terminal Here</name>
        <submenu></submenu>
        <unique-id>1788401140356715-1</unique-id>
        <command>exo-open --working-directory %f --launch TerminalEmulator</command>
        <description>Example for a custom action</description>
        <range></range>
        <patterns>*</patterns>
        <startup-notify/>
        <directories/>
      </action>
      <action>
        <icon>document-export</icon>
        <name>Convert with Filee</name>
        <submenu></submenu>
        <unique-id>filee-convert-action</unique-id>
        <command>Filee --convert %F</command>
        <description>Convert selected file(s) with Filee</description>
        <range></range>
        <patterns>*</patterns>
        <startup-notify/>
        <audio-files/>
        <image-files/>
        <other-files/>
        <text-files/>
        <video-files/>
      </action>
    </actions>
  '';
}
