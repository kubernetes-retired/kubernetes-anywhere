FROM temp/hyperkube

ADD weave-fix-nameserver.sh /fix-nameserver
ADD proxy-anywhere.sh /proxy-anywhere
CMD [ "/proxy-anywhere" ]
