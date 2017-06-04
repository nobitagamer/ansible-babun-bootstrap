#!/usr/bin/env zsh

ANSIBLE_DIR=$HOME/ansible
ANSIBLE_WORKSPACE=$HOME/ansible_workspace
AWS_CLI=0

CURRENT_DIR=$( pwd )

if [ -f /etc/ansible-babun-bootstrap.completed ]
then
    printf "First init setting up Ansible in Babun has already been completed, please wait...\n\n"
    sleep 2
    cd ${ANSIBLE_DIR}
    if [ ${BOOTSTRAP_ANSIBLE_UPDATE} ]
    then
        printf "Performing Ansible update from source, if available..."
        git pull --rebase &> /dev/null
        git submodule update --init --recursive &> /dev/null
        printf ".ok\n"
    fi
    printf "Configuring ansible virtual environment..."
    source ./hacking/env-setup &> /dev/null

    printf ".ok\nUpdating Ansible Vagrant Shims in bin Directory..."
    cp -ru $HOME/ansible-babun-bootstrap/ansible-playbook.bat $HOME/ansible/bin/ansible-playbook.bat

    printf ".ok\nLoading workspace..."
    cd ${ANSIBLE_WORKSPACE}
    sleep 3
    printf ".ok\n"
    sleep 1

    clear
    if [ ! -d  $ANSIBLE_WORKSPACE/ansible-openlink ]
    then
        printf "Retrieving ansible-openlink repository..."
        git clone https://github.com/kedwards/ansible-openlink.git $ANSIBLE_WORKSPACE/ansible-openlink &> /dev/null
    fi

    cd $ANSIBLE_WORKSPACE/ansible-openlink
    git checkout master &> /dev/null
    printf "Testing PING to all openlink servers\n"
    chmod -x conf/{.ansible_vault,vault_key}
    ansible local -i inventory -m win_ping

    clear

    figlet "MRM Automation"
    printf "\nConfigure Windows remotes with the below PS cmd\n. { iwr -useb https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 } | iex;\n\n"
else
    cd $HOME
    clear
    printf "MRM Automation Install\nThe install action may take several minutes.\n\n"
    printf "Installing deps..."
    pact install figlet gcc-g++ wget python python-crypto python-paramiko libyaml-devel libffi-devel &> /dev/null

    # Create initial Ansible hosts inventory
    # mkdir -p /etc/ansible/
    # echo "127.0.0.1" > /etc/ansible/hosts
    # chmod -x /etc/ansible/hosts

    wget https://bootstrap.pypa.io/get-pip.py &> /dev/null
    python get-pip.py &> /dev/null
    rm -r get-pip.py

    curl -sL https://github.com/pallets/markupsafe/archive/master.zip -o markupsafe.zip
    unzip markupsafe.zip &> /dev/null
    cd markupsafe-master
    python setup.py --without-speedups install &> /dev/null
    cd $HOME
    rm -rf markupsafe*

    if [ $AWS_CLI = 1 ]
    then
        pip install pywinrm cryptography pyyaml jinja2 httplib2 boto awscli &> /dev/null
    else
        pip install pywinrm cryptography pyyaml jinja2 &> /dev/null
    fi
    printf ".ok\n"

    printf "Installing ansible..."
    git clone https://github.com/ansible/ansible.git --recursive $ANSIBLE_DIR  &> /dev/null
    source $ANSIBLE_DIR/hacking/env-setup &> /dev/null

    cp $ANSIBLE_DIR/examples/ansible.cfg ~/.ansible.cfg
    # Use paramiko to allow passwords and disable host key checking for performance.
    sed -i 's|#\?transport.*$|transport = paramiko|;s|#host_key_checking = False|host_key_checking = False|' ~/.ansible.cfg

    touch /etc/ansible-babun-bootstrap.completed
    printf ".ok\n"

    printf "Seeding test project..."
    mkdir -p ~/ansible_workspace/test/{conf,inventory}
    touch ~/ansible_workspace/test/conf/{.ansible_vault,vault_key}
    chmod -x ~/ansible_workspace/test/conf/{.ansible_vault,vault_key}
    cat > ~/ansible_workspace/test/inventory/hosts << 'EOF'
# Local control machine
[local]
localhost ansible_connection=local
EOF

    cat > ~/ansible_workspace/test/ansible.cfg << 'EOF'
[defaults]
ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}
inventory = inventory/
module_name = ping
callback_plugins = callback_plugins/
filter_plugins = filter_plugins/
var_plugins = var_plugins/
retry_files_enabled = False
forks = 50
vault_password_file = conf/.ansible_vault

[filters]
vault_filter_key = conf/vault_key
vault_filter_salt =
vault_filter_iterations = 1000000
vault_filter_generate_key = yes

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=30m -o StrictHostKeyChecking=no
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

[privilege_escalation]
become_user = true
EOF
    printf ".ok\n"
    printf "configuring zhell for ansible.."

    cat >> ~/.zshrc <<'EOF'
#
# Ansible in Babun
#
# If you want to update Ansible every time set BOOTSTRAP_ANSIBLE_UPDATE=1
export BOOTSTRAP_ANSIBLE_UPDATE=0
# Configure Babun for Ansible
source ~/ansible-babun-bootstrap/ansible-babun-bootstrap.sh
# Figlet Banner
figlet "MRM Automation"
cd ~/ansible_workspace
EOF

    printf ".ok\n\n"
    echo "MRM Automation completed, redirecting...!"
    sleep 2
    cd $ANSIBLE_WORKSPACE/test
    clear
    figlet "MRM Automation"
    printf "Testing ansible local connection...\n"
    ansible local -m ping

    if [ ! -d  $ANSIBLE_WORKSPACE/ansible-openlink ]
    then
        printf "Retrieving ansible-openlink repository..."
        git clone https://github.com/kedwards/ansible-openlink.git $ANSIBLE_WORKSPACE/ansible-openlink &> /dev/null
    fi
    printf ".ok\n"

    cd $ANSIBLE_WORKSPACE/ansible-openlink
    git checkout master &> /dev/null
    printf ".ok\nTesting PING to all openlink servers\n"

    touch conf/{.ansible_vault,vault_key}
    chmod -x conf/{.ansible_vault,vault_key}
	  ansible local -i inventory -m win_ping
fi
