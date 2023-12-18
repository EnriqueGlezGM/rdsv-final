FROM educaredes/vnf-access
# install required packages
RUN apt-get clean
RUN apt-get update \
    && apt-get install -y \
    iptables \
    arpwatch

COPY README.txt /home/README.txt

COPY vnx_config_nat vnx_config_nat

RUN chmod +x vnx_config_nat

