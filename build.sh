#!/bin/bash

set -xe

apt update
apt upgrade -y
apt install -y ansible

git clone --depth 1 https://git.linaro.org/ci/job/configs.git
cd configs/ldcg-python-tensorflow/tensorflow
ansible-playbook -i inventory playbooks/run.yml
