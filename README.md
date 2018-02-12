# Network Security - Build a Linux Firewall (hosted [here](https://github.com/mishajw/iptables_docker))

For this assignment, I decided to use Docker as the environment for setting up the virtual machines (or in this case containers) as a learning experience - Docker is a tool I've been meaning to learn for a while. This yielded many pros and cons (quite a lot more cons than anticipated!), which I will discuss in the conclusion.

Because of docker, all containers were started and torn down at test time, so no clean up of `iptables` was needed in any of the scripts. This could easily be amended by putting in `iptables -F` at the beginning of every script (and removing any chains defined in the rules, as is the case for part 6).

As a result of this, all tests are bundled in with my submission, and can be run very easily; given docker is up and running with docker-compose, you can run:

```bash
git clone https://github.com/mishajw/iptables_docker
cd iptables_docker
for i in `seq 1 6`; do
  ./tests/test${i}.sh
done
```

Each test will start all containers, run tests, print "Success" if the tests were successful, and stop all containers. If the tests are unsuccessful, then the reasons for this are printed instead.

All parts are tested with test scripts, with the exception of some sections of part 5 which were more difficult to test - if I had had more time for this assignment, I would have completed these. Instead I detail how I manually tested this.

## Part 1 - Setup

Setting up docker for this assignment took a while, and the main results of this are shown in `./Dockerfile` and `./docker-compose.yaml`. Everything is self contained in these files, apart from part-specific commands that are run at test time.

You can see the simple set up in `./docker-compose.yaml` - three services (`client`, `router` and `server`) and two networks (`server_net` and `client_net`), each connected appropriately. Each container has SSH and a simple web server that serves `Hello, world!`.

The main issue I had here was overriding Docker's routing system. For this to work, I set the network's gateway to be some dummy IP, in this case `192.168.{100,101}.123`. The setting up of the default gateways is instead done in the ``. The setting up of the default gateways is instead done in the `./Dockerfile`. We pass in a subnet parameter from `./docker-compose.yaml` and call:

```bash
route add default gw ${gateway_subaddress}.1 && \
route del -net 0.0.0.0 gw ${gateway_subaddress}.123 && \
...
```

This successfully overrides the gateway introduced by docker.

The Dockerfile is also relatively simple. I use a lightweight Alpine Linux base image with Python 3.6 installed. Python is only used to set up a simple HTTP server.

The Dockerfile then runs a series of commands:

1) Installs a bunch of packages for the assignment including bash, openssh, curl, iptables.
2) It then removes the cached package installation files to reduce the image size (after all, if we're using Alpine Linux, shouldn't we try to get the image to be as small as possible..?).
3) The next thing we do is set up the SSH daemon. To do this, we need to:
    1) Generate server keys for RSA, DSA, ECDSA, and ED25519.
    2) Allow root login between the machines.
    3) Allow password authentication for the machines.
    4) Allow empty passwords.
    5) Remove the `root` password*.
4) Write `Hello, world!` to `/var/www` for the HTTP server
5) Set up the gateways as discussed above, by removing the default and adding a new one with the address of the router.
6) Starting the SSH daemon.
7) Starting the HTTP server.

\*Obviously all of this is horrible real-world practice (you probably shouldn't even have SSH running in containers)! But for the purposes of this assignment, it means we don't have to worry about sharing keys between the containers, or setting up multiple accounts for the simple purpose of testing SSH connections.

In the tests for part 1, I loop through every pair of containers, and check that you can SSH and curl between them.

## Part 2 - Default Permit on Server

The solution for this part was a simple `iptables` command run on the server, dropping all traffic on port 80.

To test this, I start up the containers, and check that the client can SSH to the server, but not curl it. The scripts are trivial and can be seen in `./common.sh` and `./tests/test2.sh`. Most scripts that check for dropped packets have a short time out of around a second, as all containers are running locally this should not be an issue and speeds up test times significantly.

## Part 3 - Default Deny on Server

The solution for this was equally as simple, which adds a rule that drops any inbound TCP traffic that isn't on port 22. The test for this is a bit more complicated: it tries a series of random ports to connect to, and ensures that pakcets are dropped by waiting for timeout.

## Part 4 - Router Filtering

There are two parts to this solution, replicating part 2 and 3. The replication of part 2 can be seen in `./part4_default_permit.sh`, with a correspoding test in `./tests/part4_default_permit.sh`.

The default permit solution is simple, and just drops all `FORWARD` packets between the server and client on port 80. The tests are identical to part 2.

The default deny solution is more complicated, with three rules:
1) Accept any packet from client to server on port 22.
2) Accept any packet that is part of an established connection (the `state` extension is needed for this) or a new connection that is part of an existing one. Without this, the packets would be able to be sent from client to server but not from server to client.
3) Drop all other packets.

This is tested identically to part 3.

## Part 5 - BCP38 Ingress and Egress Control

This solution had several parts, each initialised and tested separately:

### Blocking Private Subnets

This was done in two rules, the first setting an `ACCEPT` rule for our two local subnets `192.168.{100.101}.0/24` going from `client_net` to `server_net`. The second blocked all traffic going from `client_net` to `server_net` that belonged to any of the IP ranges defined under RFC1918 under heading "3. Private Address Space". As this rule was added after the first, traffic from our subnets are still allowed.

This was the most complicated test setup. I chose to start `tcpdump` dumping to a file on the server, and then I used `nmap` on the client to forge client IPs. This required several flags to be set:
1) `-S $FORGED_IP` to set the sender IP.
2) `-e eth0` had to be specified for `-S` to work.
3) `--disable-arp-ping` had to be set, otherwise `nmap` would send ARP request to the router to check the server existed, and when the server send back traffic to the forged IP, `nmap` would not get a response and hang.
4) `-sU` was set to use UDP packets so `nmap` wouldn't try and set up a TCP handshake
5) `-Pn` had to be set so `nmap` would just send packets rather than check if the host was up.

In hindsight, it might have been better to use a more lightweight solution, such as setting `iptables` rules, but `nmap` worked fine once the appropriate flags were set.

Once `nmap` was run with forged IPs from every blocked IP range, the `tcpdump` dump was grepped to make sure that these packets came through to the server. The process was run again with the `iptables` rules applied, and the dump was grepped again to make sure the IPs didn't exist. This worked fine, and be run in the script `./tests/test5.sh`.

### Block Bad IPs from Server Net

This was a simple rule that dropped all packets that weren't from the IP range `192.168.101.0/24` on `server_net`. This was tested in the same way as the previous rules, but with the server and client reversed.

Unfortunately, I didn't have time to write test scripts for this, but the testing was the same as above. I set up `tcpdump` on the client side, and grepped for packets coming from the IP address `192.168.102.234`, and then spoofed traffic from the server side using the `nmap` command detailed in the previous section. Before the `iptables` command was executed, the packets made it through:

```bash
09:21:49.854486 IP 192.168.102.234.54627 > 192.168.100.2.12345: UDP, length 0
```

After the `iptables` commands were run, these packets did not make it through.

### Block Broadcast Packets

To block broadcast, the `iptables` command is quite simple: it only needs to specify the two network's broadcast IPs `192.168.{100,101}.255`, and specifiy (using the `pkttype` extention) to drop all broadcast packets.

This was again tested manually. A broadcast packet was sent using:

```bash
echo test | nc -u 192.168.100.255
```

Unfortunately, this had no effect before the `iptables` rule was set up. I could not configure the containers to correctly handle broadcast packets. I suspect this could be one of several issues:

1) The router was somehow configured to drop all broadcast packets at a lower level.
2) The `nc` version in Alpine Linux does not support sending broadcast packets.

However, once the `iptables` rule was added, you can see the dropped packet counter in `iptables` increase. This can be seen when you run `iptables -L -n` - each table has a dropped packet counter that is incremented when the chain drops a packet.

## Part 6

The solution for part 6 included the `iptables` rules from part 4, with the change that instead of dropping packets, packets were `jump`ed to a new chain `LOGANDDROP`.

The `LOGANDDROP` chain used the `hashlimit` `iptables` extension. This extension allows us to filter out packets that breach (or don't breach) some limit, but also allows us to handle this based of source/destination IP/port. We have to set several parameters to get this to work as the assignment says:
1) `--hashlimit-mode srcip,dstport` sets the limiting to work per source IP and destination port pair.
2) `--hashlimit-upto 1/second` matches packets that have a rate of less than 1 per second.
3) `--hashlimit-burst 1` gets rid of the burst functionality `hashlimit` brings, as we only care about raw packet rates.

If this rule matches, we `jump` to the `NFLOG` chain. Originally, I tried to get this to work with the `LOG` chain, which directs logs directly to `syslog`. However, this functionality was removed from LXC containers in linux, as per [this](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=69b34fb996b2eee3970548cf6eb516d3ecb5eeed) commit. However, `NFLOG` doesn't interface with `syslog`, so it worked a charm.

To get this to work, I had to install the `ulogd` command, enable a line in it's configuration, and start it up. All of this can be seen in `./tests/part6.sh`.

To check the logs, the client would try and curl the server 10 times, and then we would check the logs on the server. If we found that the logs had logged 10 separate connection attempts, then the log rate limiting had failed. Fortunately, this worked fine once the logging configuration was set up correctly, and `iptables` rate limiting worked perfectly.

## Epilogue - Experience with Docker

Overall, working with docker was a fun learning experience, although it introduced some issues along the way. Using `NFLOG` wasn't too hacky, but having to bypass docker's routing system manually using the `route` command felt like a hack, and it would be nice if there was an easier way to configure all of this within `docker-compose`. Especially as this seems like what could be a common usage of `docker-compose` in order to separate out containers in different networks, if some containers aren't as trusted as others.

Docker also allowed for a reliable testing environment, removing state from all of the tests - so I didn't have to worry about experiments from previous sections affecting later ones. I also didn't have to worry about losing work that I had done inside containers, because as long as the work was in `./Dockerfile` or `./docker-compose.yaml` and committed, I could easily boot up the containers again.

