FROM ubuntu:18.04
LABEL maintainer "Jordi Cenzano <jordi.cenzano@gmail.com>"

# Update
RUN apt-get update -y

# Upgrade
RUN apt-get upgrade -y

# Upgrade
RUN apt-get install -y socat

# Install network resources
RUN apt-get -y install iputils-ping net-tools iproute2 iperf3

COPY tcp-proxy.sh /usr/bin/tcp-proxy

ENTRYPOINT ["tcp-proxy"]