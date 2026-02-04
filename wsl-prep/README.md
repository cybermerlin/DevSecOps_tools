# WSL prepare

Scripts to prepare Ubuntu under WSL.
Including base installations and reconfigurations.

Before, you need run:
```sh
mkdir -p ~/dev/admin
# copy scripts into Ubuntu's ~/dev/admin/ directory
time sudo rsync -av /mnt/f/dev/projects/admin/wsl-prep ~/dev/admin/ && cd ~/dev/admin/wsl-prep
```

and then:
```sh
./run.sh prep
./run.sh fix
./run.sh upgrade
./run.sh inst
```

Each time in the console you can see some warnings for you to do smth... some manual actions (restart WSL or smth else) - pls, do it and go ahead.

## Read it to advance

- https://learn.microsoft.com/ru-ru/windows/wsl/use-custom-distro?source=recommendations

## Hyper-V + WSL Network

- **hyperv-wsl-network.ps1** script to get all current network configuration to reproduce it in another Win-host.

## Structure

- [win](./win/README.md) to works with WSL (add a new WSL machine, clone or del)
- [wsl-files](wsl-files/) configs and some scripts from /etc, /usr, ... to copy-paste into a new system
- [wsl-nat](wsl-nat/) scripts to configure as a NAT your WSL-Ubuntu system
- [getter cur network conf](get-hyperv-wsl-network.ps1) to backup it
- [setter network conf](set-hyperv-wsl-network.ps1)  for your win-host to preset an Internet saccess for Hyper-V and WSL
