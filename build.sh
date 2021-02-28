#!/bin/bash

set -xe
sudo apt-add-repository ppa:ansible/ansible
sudo apt update -y
#apt upgrade -y
sudo apt install -y ansible
python3 -V
pip -V
#pip install --upgrade pip
#git clone --depth 1 https://git.linaro.org/ci/job/configs.git
cd configs/ldcg-python-tensorflow/tensorflow
ansible-playbook -i inventory --verbose  playbooks/run.yml
