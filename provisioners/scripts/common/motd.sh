#!/bin/sh -eux

devops='
This system was built with the FSO Lab DevOps project by the AppDynamics Cloud Channel Sales Team.
More information can be found at: https://github.com/APO-SRE/fso-lab-devops.git'

if [ -d /etc/update-motd.d ]; then
    MOTD_CONFIG='/etc/update-motd.d/99-devops'

    cat >> "$MOTD_CONFIG" <<DEVOPS
#!/bin/sh

cat <<'EOF'
$devops
EOF
DEVOPS

    chmod 0755 "$MOTD_CONFIG"
else
    echo "$devops" >> /etc/motd
fi