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
iperf -c host.docker.internal -i 2 -t 300 -p 6000
```
- Run iperf client in the container. To open a shell in the container `make shell`

```bash
apt-get install iperf
iperf -c host.docker.internal -i 2 -t 300 -p 6000
```
- At this point you should see quite high thoughput, example:
```
...
[  4] 108.0-110.0 sec   114 MBytes   477 Mbits/sec
[  4] 110.0-112.0 sec   112 MBytes   471 Mbits/sec
[  4] 112.0-114.0 sec   117 MBytes   490 Mbits/sec
[  4] 114.0-116.0 sec   115 MBytes   482 Mbits/sec
[  4] 116.0-118.0 sec   121 MBytes   508 Mbits/sec
[  4] 118.0-120.0 sec   122 MBytes   512 Mbits/sec
[  4] 120.0-122.0 sec   122 MBytes   511 Mbits/sec
...
```

- Limit the container interface to 1Mbps (to get the `DOCKER-INSTANCE-ID` you can do `docker ps`)
```
docker exec DOCKER-INSTANCE-ID sh -c "tc qdisc add dev eth0 root netem rate 1000kbit"
```

- At this point you should see the throughput decreases to 1Mbps:
```
...
[  4] 116.0-118.0 sec   121 MBytes   508 Mbits/sec
[  4] 118.0-120.0 sec   122 MBytes   512 Mbits/sec
[  4] 120.0-122.0 sec   122 MBytes   511 Mbits/sec
[  4] 122.0-124.0 sec  28.5 MBytes   120 Mbits/sec
[  4] 124.0-126.0 sec   402 KBytes  1.65 Mbits/sec <--- HERE GOES DOWN to 1Mbps
[  4] 126.0-128.0 sec   237 KBytes   969 Kbits/sec
[  4] 128.0-130.0 sec   235 KBytes   964 Kbits/sec
[  4] 130.0-132.0 sec   235 KBytes   964 Kbits/sec
[  4] 132.0-134.0 sec   235 KBytes   964 Kbits/sec
...
```

- Remove the interface limits
```bash
docker exec DOCKER-INSTANCE-ID sh -c "tc qdisc del dev eth0 root netem"
```