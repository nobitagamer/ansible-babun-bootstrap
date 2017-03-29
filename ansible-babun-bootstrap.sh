#!/usr/bin/env zsh

HOME=~
ANSIBLE_DIR=$HOME/ansible
CURRENT_DIR=$(pwd)
AWS_CLI=0

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
	sleep 1
	clear
else
	printf "\n~ MRM Ansible Install ~\n\n"
	printf "installing dependencies.."
    pact install figlet gcc-g++ wget python python-crypto python-paramiko libyaml-devel libffi-devel &> /dev/null
	
	wget https://bootstrap.pypa.io/get-pip.py &> /dev/null
	python get-pip.py &> /dev/null
	rm -r get-pip.py
	
	if [ $AWS_CLI = 1 ] 
	then
		pip install markupsafe --install-option="--without-speedups" pywinrm cryptography pyyaml jinja2 httplib2 boto awscli &> /dev/null
	else
		pip install markupsafe --install-option="--without-speedups" pywinrm cryptography pyyaml jinja2 &> /dev/null
	fi
	printf ".ok\n"
	
	printf "installing ansible.."
	git clone https://github.com/ansible/ansible.git --recursive $ANSIBLE_DIR  &> /dev/null
	cd $ANSIBLE_DIR
	source ./hacking/env-setup &> /dev/null
	cd $CURRENT_DIR
	
	cp $ANSIBLE_DIR/examples/ansible.cfg ~/.ansible.cfg
	sed -i 's|#\?transport.*$|transport = paramiko|;s|#host_key_checking = False|host_key_checking = False|' ~/.ansible.cfg

	touch /etc/ansible-babun-bootstrap.completed
    printf ".ok\n"    

	printf "creating test project.."
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
	printf ".ok\n"    
	printf "configuring zshell for ansible.."
	
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
	echo "Ansible in Babun completed, please restart Babun!"
fi
