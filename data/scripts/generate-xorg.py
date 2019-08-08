import subprocess

file = "/usr/share/X11/xorg.conf.d/20-nvidia-dynamic.conf"

# Reading GPU via lspci
vga = subprocess.Popen("lspci | grep 'VGA compatible controller:'", shell=True, stdout=subprocess.PIPE)
out, err = vga.communicate()
raw = out.split("\n")


if not raw:
  print "Failed to generate configuration"
  exit()


## Generating the ServerLayout portion
markup  = "Section \"ServerLayout\"\n"
markup += "  Identifier \"Layout0\"\n"

for idx, line in enumerate(raw):
  if not line:
    continue

  if idx == 0:
    markup += "  Screen %s \"Screen%s\"\n" % (idx, idx)
  else:
    markup += "  Screen %s  \"Screen%s\" RightOf \"Screen%s\"\n" % (idx, idx, idx - 1)

markup += "EndSection\n"


for idx, line in enumerate(raw):
  try:

    if 'Intel Corporation' in line:
      driver = "intel"
      vendor = "Intel Corporation"
      board  = "Intel"

    if 'NVIDIA Corporation' in line:
      driver = "nvidia"
      vendor = "Nvidia Corporation"
      board  = "Nvidia"

    p = line[:7]
    pci1 = int(p.split(':')[0])
    pci2 = int(p.split(':')[1].split('.')[0])
    pci3 = int(p.split('.')[1])
    pci = "PCI:%s:%s:%s" % (pci1, pci2, pci3)


    # Generating monitor section
    markup += "Section \"Monitor\"\n"
    markup += "  Identifier   \"Monitor%s\"\n" % (idx)
    markup += "  VendorName   \"Unknown\"\n"
    markup += "  ModelName    \"Unknown\"\n"
    markup += "  Option       \"DPMS\"\n"
    markup += "EndSection\n"


    # Generating device section
    markup += "Section \"Device\"\n"
    markup += "  Identifier   \"Device%s\"\n" % (idx)
    markup += "  Driver       \"%s\"\n" % (driver)
    markup += "  VendorName   \"%s\"\n" % (vendor)
    markup += "  BoardName    \"%s\"\n" % (board)
    markup += "  BusID        \"%s\"\n" % (pci)
    markup += "EndSection\n"

    # Generating screen section
    markup += "Section \"Screen\"\n"
    markup += "  Identifier   \"Screen%s\"\n" % (idx)
    markup += "  Device       \"Device%s\"\n" % (idx)
    markup += "  Monitor      \"Monitor%s\"\n" % (idx)
    markup += "  DefaultDepth 24\n"

    if 'NVIDIA Corporation' in line:
      markup += "  Option \"AllowEmptyConfiguration\" \"True\"\n"
      markup += "  Option \"UseDisplayDevice\" \"DFP-0:/etc/X11/edid.bin\"\n"
      markup += "  Option \"Coolbits\" \"31\"\n"
      markup += "  Option \"ConnectedMonitor\" \"DFP=0\"\n"
      markup += "  SubSection \"Display\"\n"
      markup += "    Depth 24\n"
      markup += "  EndSubSection\n"

    markup += "EndSection\n"


  except:
    pass


# Generate the file
if markup:
  f = open(file, 'w')
  f.write(markup)
  f.close()
  print "Configuration file generated at %s" % (file)

exit()


