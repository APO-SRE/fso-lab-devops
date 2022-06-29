#!/bin/sh -eux
#---------------------------------------------------------------------------------------------------
# Install MongoDB Community Server 5.0 on Amazon Linux 2.
#
# MongoDB is a document database designed for ease of development and scaling. It is
# source-available, cross-platform, and classified as a NoSQL database program, MongoDB uses
# JSON-like documents with optional schemas.
#
# For more details, please visit:
#   https://www.mongodb.com/docs/manual/introduction/
#   https://www.mongodb.com/try/download/community/
#   https://www.mongodb.com/docs/upcoming/tutorial/install-mongodb-on-amazon/
#
# NOTE: Script should be run with 'root' privilege.
#---------------------------------------------------------------------------------------------------

# prepare the mongodb repository for installation. -------------------------------------------------
# create the mongodb repository.
cat <<EOF > /etc/yum.repos.d/mongodb-org-5.0.repo
[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
EOF

# install the mongodb database. --------------------------------------------------------------------
yum -y install mongodb-org

# configure mongodb server. ------------------------------------------------------------------------
# reload systemd manager configuration.
systemctl daemon-reload

# start the mongodb service and configure it to start at boot time.
systemctl start mongod
systemctl enable mongod
systemctl is-enabled mongod

# check that the mongodb service is running.
systemctl status mongod

# verify installation. -----------------------------------------------------------------------------
# set mongodb shell environment variables.
PATH=/usr/bin:$PATH
export PATH

# verify mongodb version.
mongo --version

# verify mongodb shell version.
mongosh --version
