# tcp-proxy-docker

## Description

Simple utility to relay tcp traffic to a specific host and port.

It can be useful also to add interference (test under stress) a TCP based network connection (ex: Live streaming)

# Pulling docker image from docker hub
1. Ensure you have [docker](https://www.docker.com) installed
2. Type: `docker pull jcenzano/docker-tcp-proxy`

# Creating the docker image locally (optional)
1. Ensure you have docker [docker](https://www.docker.com) 
2. Clone this repo `git clone git@github.com:jordicenzano/tcp-proxy-docker.git`
2. From the root dir of this repo `make`

## Localhost usage
```bash
./tcp-proxy.sh listenPort DestHost DestPort
```

## Examples of docker usage
To relay all TCP connections on your port `1234` to `my.cool.host:80`:

```bash
docker run -it --rm -p 1234:2000 jcenzano/tcp-proxy 2000 my.cool.host 80
```

## Simulating bad network

You can simulate bad networks conditions (rate, loss, delays, corrupt, duplication, reordering) using netem [more info](https://www.man7.org/linux/man-pages/man8/tc-netem.8.html)

In the following example we will simulate 1Mbps of BW streaming to Facebook

- Start your TCP proxy container:
```bash
docker run -itd --cap-add=NET_ADMIN --name tcp-relay --rm -p 1935:2000 jcenzano/docker-tcp-proxy:latest 2000 rtmp-pc.facebook.com 443
```

- Start streaming, you can use a software encoder (Example: OBS, Wirecast) (*), or `ffmpeg`. **Remember to point to `localhost:1935`**
```bash
ffmpeg -hide_banner -y \
-f lavfi -re -i smptebars=size=1280x720:rate=30 \
-f lavfi -i sine=frequency=1000:sample_rate=48000 -pix_fmt yuv420p \
-c:v libx264 -b:v 6000k -g 60 -profile:v baseline -preset veryfast \
-c:a aac -b:a 48k \
-f flv "rtmps://localhost:1935/rtmp/MY-STREAM-KEY"
```
(*) With OBS in MAC you could have certificate problems using RTMPS

- Limit your network to 1Mbps
```bash
docker exec tcp-relay sh -c "tc qdisc add dev eth0 root netem rate 1000kbit"
```

- At this point you can observe/measure how your communication protocol deals with those BW restrictions

- Finally remove your network limits
```bash
docker exec tcp-relay sh -c "tc qdisc del dev eth0 root"
```

## How to test it works

- Run this command in localhost (iperf server)
```bash
iperf -s -i 2 -p 6000
```
- Start the `tcp-proxy-docker` with this command to get packets from 1935 in localhost and send it (internally) to localhost (`host.docker.internal`) port 6000
```bash
docker run -it --cap-add=NET_ADMIN --name test-net --rm -p 1935:2000 jcenzano/docker-tcp-proxy:latest 2000 host.docker.internal 6000
```
- Start `iperf` client in localhost pointing to port 1935
```bash
iperf -c localhost -i 2 -t 300 -p 1935
```

- At this point you should see quite high throughput, example:
```
...
[  4]  0.0- 2.0 sec  62.9 MBytes   264 Mbits/sec
[  4]  2.0- 4.0 sec  73.7 MBytes   309 Mbits/sec
[  4]  4.0- 6.0 sec  75.1 MBytes   315 Mbits/sec
[  4]  6.0- 8.0 sec  72.2 MBytes   303 Mbits/sec
[  4]  8.0-10.0 sec  64.7 MBytes   271 Mbits/sec
[  4] 10.0-12.0 sec  58.0 MBytes   243 Mbits/sec
[  4] 12.0-14.0 sec  62.1 MBytes   260 Mbits/sec
...
```

- Limit the container interface to 1Mbps
```bash
docker exec test-net sh -c "tc qdisc add dev eth0 root netem rate 1000kbit"
```

- At this point you should see the throughput decreases to 1Mbps:
```
...
[  4] 28.0-30.0 sec  61.1 MBytes   256 Mbits/sec
[  4] 30.0-32.0 sec  61.4 MBytes   258 Mbits/sec
[  4] 32.0-34.0 sec  57.2 MBytes   240 Mbits/sec
[  4] 34.0-36.0 sec  52.7 MBytes   221 Mbits/sec
[  4] 36.0-38.0 sec   212 KBytes   870 Kbits/sec <-- Limit to 1Mbps
[  4] 38.0-40.0 sec   235 KBytes   964 Kbits/sec
[  4] 40.0-42.0 sec   235 KBytes   964 Kbits/sec
...
```

- Remove the interface limits
```bash
docker exec test-net sh -c "tc qdisc del dev eth0 root netem"
```
