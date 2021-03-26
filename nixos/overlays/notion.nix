self: super: {
  # Need to add a patch. This is fixed in Notion 4.0.2 but it's not
  # backported to nixos-20.09.
  notion = super.notion.overrideAttrs (old: {
    patches = [ ./notion-timer.patch ];
  });
}
