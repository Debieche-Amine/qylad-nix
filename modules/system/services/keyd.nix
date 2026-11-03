{...}: {
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            capslock = "space";
            rightshift = "rightshift";
            rightcontrol = "rightcontrol";
          };
        };
      };
    };
  };
}
