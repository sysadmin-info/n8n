#!/bin/bash -e

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')]: $*"
}

# Function to display spinner
display_spinner() {
  local pid=$1
  local spin='-\|/'

  log "Loading..."

  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spin#?}
    printf "\r [%c]" "$spin"
    local spin=$temp${spin%"$temp"}
    sleep 0.1
  done
  printf "\r"
}

row=2
col=2

countdown() {
        msg="Wait 30 seconds for n8n ${1}..."
        clear
        tput cup $row $col
        echo -n "$msg"
        l=${#msg}
        l=$(( l+$col ))
        for i in {30..1}
        do
                tput cup $row $l
                echo -n "$i"
                sleep 1
        done
}

execute_command() {
  local cmd="$*"
  log "Executing: $cmd"
  bash -c "$cmd" &
  display_spinner $!
}

error_exit() {
  log "$1"
  exit 1
}

check_root(){
  echo "This quick installer script requires root privileges."
  echo "Checking..."
  if [[ $(/usr/bin/id -u) -ne 0 ]]; 
    then
      echo "Not running as root"
      exit 0
  else
      echo "Installation continues"
  fi

  SUDO=
  if [ "$UID" != "0" ]; then
        if [ -e /usr/bin/sudo -o -e /bin/sudo ]; then
                SUDO=sudo
        else
                echo "*** This quick installer script requires root privileges."
                exit 0
        fi
  fi
}

update_upgrade(){
  echo 'updating system'
  sudo apt update
  sudo apt upgrade -y
}

check_packages(){
  if [[ $(command -v build-essential) ]]; then
    echo "build-essential already installed"
  else
    sudo apt install build-essential -y 
  fi

  if [[ $(command -v python3) ]]; then
    echo "python3 already installed"
  else
    sudo apt install python3 -y
  fi

  if [[ $(command -v nodejs) ]]; then
    echo "nodejs already installed"
  else
    sudo apt install nodejs -y
  fi

  if [[ $(command -v npm) ]]; then
    echo "npm already installed"
  else
    sudo apt install npm -y
  fi
}

install_n8n(){
  execute_command "echo 'install n8n globally'"
  npm install n8n -g
}

adding_systemd_entry(){
  echo 'adding systemd entry'
  sudo cat > /etc/systemd/system/n8n.service <<EOF
[Unit]
Description=n8n - Easily automate tasks across different services.
After=network.target

[Service]
Type=simple
User=adrian
ExecStart=/usr/local/bin/n8n start --tunnel
Restart=on-failure

[Install]
WantedBy=multi-user.target
Alias=n8n.service
EOF
}

n8n_service(){
  echo 'reloading, enabling on boot and starting n8n'
  sudo systemctl daemon-reload
  sudo systemctl enable n8n
  sudo systemctl start n8n
}

n8n_status(){
  systemctl status n8n.service
}

main(){
  check_root
  update_upgrade
  check_packages
  install_n8n
  adding_systemd_entry
  n8n_service
  countdown
  n8n_status
}

main
