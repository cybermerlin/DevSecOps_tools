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
