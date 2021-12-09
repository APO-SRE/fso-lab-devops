#!/bin/sh -eux
# install groovy sdk bundle by apache.

# install apache groovy. ---------------------------------------------------------------------------
groovy_home="groovy"
groovy_release="3.0.9"
groovy_folder="${groovy_home}-${groovy_release}"
groovy_sdk="apache-groovy-sdk-${groovy_release}.zip"
groovy_sha256="8bce7b90612bcfe8d19adce26335b25a9955aeaaa8a9e89df8b8769a77e97187"
#groovy_binary="apache-groovy-binary-${groovy_release}.zip"
#groovy_docs="apache-groovy-docs-${groovy_release}.zip"

# create apache parent folder.
mkdir -p /usr/local/apache
cd /usr/local/apache

# download groovy sdk bundle from apache.org.
wget --no-verbose https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/${groovy_sdk}

# verify the downloaded binary.
echo "${groovy_sha256} ${groovy_sdk}" | sha256sum --check
# apache-groovy-sdk-${groovy_release}.zip: OK

# extract groovy sdk binary.
rm -f ${groovy_home}
unzip ${groovy_sdk}
chown -R root:root ./${groovy_folder}
ln -s ${groovy_folder} ${groovy_home}
rm -f ${groovy_sdk}

# set jdk home environment variables.
JAVA_HOME=/usr/local/java/jdk180
export JAVA_HOME

# set groovy home environment variables.
GROOVY_HOME=/usr/local/apache/${groovy_home}
export GROOVY_HOME
PATH=${GROOVY_HOME}/bin:${JAVA_HOME}/bin:$PATH
export PATH

# verify installation.
groovy --version