#!/bin/sh

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    ssh "root@${FA_CONTROLLER_IP}" bash << EOS

# Configure DNS (the default DNS server must resolve the domain server)
puredns setattr --search ${DNS_SEARCH_DOMAIN_NAME} --domain ${DOMAIN_NAME} --nameservers ${DOMAIN_CONTROLLER_1_IP},${DOMAIN_CONTROLLER_2_IP} --mode static

# Delete the FA account in the AD
computer_name=\$(puread account list --nvp | sed -n 's/^Computer Name=//p' | head -1)
if [ -n "\$computer_name" ]; then
    puread account delete \$computer_name
fi

# Unset FA file gateway tunables
for tunable in PS_FILEGW_PROTOCOL_IP_ADDR PS_FILEGW_DS_SOURCE_IP_ADDR PS_FILEGW_DNS_SOURCE_IP_ADDR PS_FILEGW_ALLOW_DIALECT PS_FILEGW_NFS_ALLOW_AUTH_GSS; do
    puretune --local --ignore-puredb --unset "\$tunable"
done

# Restart the middleware and the file gateway
service middleware restart
service filegw restart
EOS
    exit $?
fi

if [ "$1" = "setup" ]; then

ssh "root@${FA_CONTROLLER_IP}" bash << EOS

set -eu
set -o pipefail

# backup original stdout to fd3 and redirect stdout to stderr
exec 3>&1
exec 1>&2

# Configure DNS (the default DNS server must resolve the domain server)
puredns setattr --search ${DNS_SEARCH_DOMAIN_NAME} --domain ${DOMAIN_NAME} --nameservers ${DOMAIN_CONTROLLER_1_IP},${DOMAIN_CONTROLLER_2_IP} --mode static

# Array setup
# ip_addr=\$(purenetwork eth list --service iscsi --nvp | sed -n 's/Address=//p' | head -1)
ip_addr=${FA_MOUNT_IP}
if [ -z "\$ip_addr" ]; then echo "Cannot determinate IP address"; exit 1; fi

values=\$(puretune --local --ignore-puredb --list PS_FILE_GATEWAY_ENABLED PS_FILEGW_PROTOCOL_IP_ADDR PS_FILEGW_DS_SOURCE_IP_ADDR PS_FILEGW_DNS_SOURCE_IP_ADDR PS_FILEGW_ALLOW_DIALECT PS_FILEGW_NFS_ALLOW_AUTH_GSS --csv 2>/dev/null | sed 's/,[^,]*,/=/;s/,.*//' || true)
resetgw=0

# Enable FA file services
if ! echo "\$values" | grep -q "PS_FILE_GATEWAY_ENABLED=1"; then
    puretune --local --ignore-puredb --set PS_FILE_GATEWAY_ENABLED 1 'file-demo'
    resetgw=1
fi

# Set FA file IP addresses
if ! echo "\$values" | grep -q "PS_FILEGW_PROTOCOL_IP_ADDR=\$ip_addr"; then
    puretune --local --ignore-puredb --set PS_FILEGW_PROTOCOL_IP_ADDR "\$ip_addr" ''
    resetgw=1
fi
if ! echo "\$values" | grep -q "PS_FILEGW_DS_SOURCE_IP_ADDR=\$ip_addr"; then
    puretune --local --ignore-puredb --set PS_FILEGW_DS_SOURCE_IP_ADDR "\$ip_addr" ''
    resetgw=1
fi
if ! echo "\$values" | grep -q "PS_FILEGW_DNS_SOURCE_IP_ADDR=\$ip_addr"; then
    puretune --local --ignore-puredb --set PS_FILEGW_DNS_SOURCE_IP_ADDR "\$ip_addr" ''
    resetgw=1
fi

# Enable FA file protocols
if ! echo "\$values" | grep -q "PS_FILEGW_ALLOW_DIALECT=1991"; then
    puretune --local --ignore-puredb --set PS_FILEGW_ALLOW_DIALECT 1991 ''
    resetgw=1
fi

# Enable FA file NFS GSS
if ! echo "\$values" | grep -q "PS_FILEGW_NFS_ALLOW_AUTH_GSS=1"; then
    puretune --local --ignore-puredb --set PS_FILEGW_NFS_ALLOW_AUTH_GSS 1 ''
    resetgw=1
fi

# Restart the middleware and the file gateway
if [ "\$resetgw" = "1" ]; then
    service middleware restart
    service filegw restart
    pureadm restart
    pureadm wait
fi

# restore stdout from fd3
exec 1>&3
EOS

exit $?
fi