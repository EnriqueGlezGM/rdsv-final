FROM      osrg/ryu

RUN apt-get clean
RUN	apt-get update && apt-get install -y \
	net-tools \
	iproute \
	inetutils-ping \
    openvswitch-switch \
    openvswitch-common \
    iperf \
    tcpdump \
    python-pip \
    git \
    iperf3 \
    curl \
    nano \
    bridge-utils \
    vim \
    arpwatch

COPY README.txt /home/README.txt

#RUN pip install -r ryu/tools/optional-requires
RUN git clone https://github.com/martimy/flowmanager
COPY qos_simple_switch_13.py qos_simple_switch_13.py
