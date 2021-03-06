#!/bin/sh -eux
# install go programming language from google.

# install go programming language. -----------------------------------------------------------------
go_home="go"
go_release="1.18.4"
go_binary="${go_home}${go_release}.linux-amd64.tar.gz"
go_folder="${go_home}-${go_release}"
go_sha256="c9b099b68d93f5c5c8a8844a89f8db07eaa58270e3a1e01804f17f4cf8df02f5"

# create apache parent folder.
mkdir -p /usr/local/google
cd /usr/local/google

# download go binary from googleapis.com.
wget --no-verbose https://storage.googleapis.com/golang/${go_binary}

# verify the downloaded binary.
echo "${go_sha256} ${go_binary}" | sha256sum --check
# ${go_home}${go_release}.linux-amd64.tar.gz: OK

# extract go binary.
rm -f ${go_home}
tar -zxvf ${go_binary} --no-same-owner --no-overwrite-dir
chown -R root:root ./${go_home}
mv ${go_home} ${go_folder}
ln -s ${go_folder} ${go_home}
rm -f ${go_binary}

# set go home environment variables.
GOROOT=/usr/local/google/${go_home}
export GOROOT
PATH=${GOROOT}/bin:$PATH
export PATH

# verify installation.
go version
