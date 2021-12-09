#!/bin/sh -eux
# install python 3.6 from the software collection library for linux 7.x..

# set default value for fso lab devops home environment variable if not set. -----------------------
devops_home="${devops_home:-/opt/fso-lab-devops}"                # [optional] devops home (defaults to '/opt/fso-lab-devops').

# create scripts directory (if needed). ------------------------------------------------------------
mkdir -p ${devops_home}/provisioners/scripts/centos
cd ${devops_home}/provisioners/scripts/centos

# install python 3.6. ------------------------------------------------------------------------------
yum -y install rh-python36

# verify installation.
scl enable rh-python36 -- python --version

# install python 3.6 pip. --------------------------------------------------------------------------
rm -f get-pip.py
wget --no-verbose https://bootstrap.pypa.io/get-pip.py
scl enable rh-python36 -- python ${devops_home}/provisioners/scripts/centos/get-pip.py

# verify installation.
scl enable rh-python36 -- pip --version
scl enable rh-python36 -- pip3 --version
