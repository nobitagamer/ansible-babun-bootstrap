#!/usr/bin/env zsh

HOME=~
ANSIBLE_DIR=$HOME/ansible
CURRENT_DIR=$(pwd)
AWS_CLI=0
DEPS="pywinrm cryptography"

if [ -f /etc/ansible-babun-bootstrap.completed ]
then
	printf "please wait...\n\n"
	cd ${ANSIBLE_DIR}
	if [ ${BOOTSTRAP_ANSIBLE_UPDATE} = 1 ]
	then
		printf "updating ansible source..."
		git pull --rebase &> /dev/null
		git submodule update --init --recursive &> /dev/null
		printf "OK\n"
	fi
	printf "configuring ansible virtual environment..."
	source ./hacking/env-setup &> /dev/null
	printf "OK\nloading workspace..."
	cd ${CURRENT_DIR}
	sleep 3
	printf "OK\n"
	sleep 2
	clear
else
	# Ansible dependencies
	pact install curl figlet gcc-g++ git libyaml-devel openssh openssl opensssl-devel python python-crypto python-devel python-jinja2 python-paramiko python-setuptools python-yaml vim wget &> /dev/null
	easy_install-2.7 pip &> /dev/null
	
	# AWS CLI
	if [ $AWS_CLI = 1 ] 
	then
		DEPS="${DEPS} httplib2 boto awscli"
	fi
	
	pip install ${DEPS}
	
	# Create initial Ansible hosts inventory and test workspace
	mkdir -p $HOME/ansible_workspace/test/{conf,inventory} /etc/ansible
	touch $HOME/ansible_workspace/test/conf/{.ansible_vault2,vault_key2}
	cat > tee $HOME/ansible_worksapce/test/inventory/hosts /etc/ansible/hosts << 'EOF'
# Local control machine
[local]
localhost ansible_connection=local
EOF
    
	cat > $HOME/ansible_worksapce/test/ansible.cfg << 'EOF'
[defaults]
ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}
inventory = inventory/
module_name = win_ping
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
	
	# Setup Ansible from Source
	mkdir -p $ANSIBLE_DIR
	git clone https://github.com/ansible/ansible.git --recursive $ANSIBLE_DIR &> /dev/null
	cd $ANSIBLE_DIR
	source ./hacking/env-setup &> /dev/null
	cd $CURRENT_DIR

	# Copy default config
	cp $ANSIBLE_DIR/examples/ansible.cfg ~/.ansible.cfg

	# Use paramiko to allow passwords
	sed -i 's|#\?transport.*$|transport = paramiko|' ~/.ansible.cfg

	# Disable host key checking for performance
	sed -i 's|#host_key_checking = False|host_key_checking = False|' ~/.ansible.cfg
	
	# touch a file to mark first app init completed
	touch /etc/ansible-babun-bootstrap.completed
	
	# Set this script to run at Babun startup
	cat >> $HOME/.zshrc <<'EOF'

#
# Ansible in Babun
#

# If you want to update Ansible every time set BOOTSTRAP_ANSIBLE_UPDATE=1
export BOOTSTRAP_ANSIBLE_UPDATE=0

# Configure Babun for Ansible
source $HOME/ansible-babun-bootstrap/ansible-babun-bootstrap.sh

# Figlet Banner
figlet "MRM Automation"
cd $HOME/ansible_workspace
EOF

	echo "Ansible in Babun completed, please restart Babun!"
fi
