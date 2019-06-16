FROM tig4605246/oaicn:1.0
RUN systemctl enable snapd
RUN snap install core --channel=edge

COPY ./oaicn_hss_init.sh /root/hss_init.sh
CMD ["/root/hss_init.sh"]