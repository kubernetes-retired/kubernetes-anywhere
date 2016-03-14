FROM temp/hyperkube

ADD weave-fix-nameserver.sh /fix-nameserver
ADD kubelet-anywhere.sh /kubelet-anywhere
CMD [ "/kubelet-anywhere" ]
