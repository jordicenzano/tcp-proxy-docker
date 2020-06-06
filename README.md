# tcp-proxy-docker

## Description

Simple utility to relay tcp traffic to a specific host and port.

It can be useful also to add interferinece (test under stress) a TCP based network connection (ex: Live streaming)

# Pulling docker image from docker hub
1. Ensure you have [docker](https://www.docker.com) installed
2. Type: `docker pull jcenzano/docker-tcp-proxy`

# Creating the docker image locally (optional)
1. Ensure you have docker [docker](https://www.docker.com) 
2. Clone this repo `git clone XXXX`
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

- Limit your network to 1Mbps
```bash
docker exec tcp-relay sh -c "tc qdisc add dev eth0 root netem rate 1000kbit"
```

- At this point you can observe/measure how your communicatin protocol deals with those BW restrictions

- Finally remove your network limits
```bash
docker exec tcp-relay sh -c "tc qdisc del dev eth0 root"
```
