FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends bind9 bind9-utils dnsutils python3 python3-dnspython tcpdump procps ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /lab
COPY lab/ /lab/
RUN chmod +x /lab/*.sh
ENTRYPOINT ["/lab/entrypoint.sh"]
