# Remote Development
This article explains how to develop using local FPGA and remote Vivado installation.

## Option 1: hw_server
It is possible to install only hardware server part of Vivado suite to your machine and use remote installation of Vivado design suite.

1) Download Vivado Design Suite Installer from official AMD (Xilinx) website.
2) During installation process, choose Hardware Server for installation.
3) Finish the installation.
4) Launch hardware server.
5) Forward hardware server port to your remote server where the Vivado is installed (for example using SSH).
6) Open hardware manager in your remote hardware installation.
7) Click "Open target" and "Open new target".
8) In the wizard, click "Next", pick "Remote server" in "Connect to" and fill in hostname and port accoring to your forwarding options. If you forwarded the default port using SSH, fill in "localhost" as hostname and 3121 as port. Click "Next", confirm you see your FPGA in the list and click "Next" and "Finish.".
9) If everything went well, you can now use hardware manager for programming and debugging as usual.