{...}: {
  programs.qutebrowser = {
    enable = true;

    extraConfig = ''
      # AZERTY top-row keys and number tab bindings
      azerty_tabs = [
          ('&', 1),
          ('é', 2),
          ('"', 3),
          ("'", 4),
          ('(', 5),
          ('-', 6),
          ('è', 7),
          ('_', 8),
          ('ç', 9),
          ('à', -1),
          ('1', 1),
          ('2', 2),
          ('3', 3),
          ('4', 4),
          ('5', 5),
          ('6', 6),
          ('7', 7),
          ('8', 8),
          ('9', 9),
          ('0', -1),
      ]

      modes = ['normal', 'insert', 'passthrough', 'command', 'prompt', 'caret']

      for key, tab in azerty_tabs:
          for mode in modes:
              config.bind(f'<Alt-{key}>', f'tab-focus {tab}', mode=mode)

      # Map unshifted characters for count prefixes and vim numbers
      c.bindings.key_mappings.update({
          '&': '1',
          'é': '2',
          '"': '3',
          "'": '4',
          '(': '5',
          '-': '6',
          'è': '7',
          '_': '8',
          'ç': '9',
          'à': '0',
      })
    '';

    keyBindings = {
      normal = {
        "b" = "set-cmd-text -s :buffer ";
      };
    };
  };
}
