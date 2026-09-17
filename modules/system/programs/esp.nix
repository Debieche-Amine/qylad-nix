{username, ...}: {
  # Serial port / USB device permissions for flashing ESP microcontrollers
  users.users.${username}.extraGroups = [
    "dialout"
    "uucp"
  ];
}
