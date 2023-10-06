# Ubuntu commands
netstat -tnpa | grep 'ESTABLISHED.*sshd'

# CentOS commands
tcpdump -i ens160 icmp and icmp[icmptype]=icmp-echo