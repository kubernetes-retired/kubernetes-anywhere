FROM gcr.io/google_containers/hyperkube:v1.1.8
LABEL works.weave.role=system

ADD weave-fix-nameserver.sh /fix-nameserver
ADD kubelet-anywhere.sh /kubelet-anywhere
CMD [ "/kubelet-anywhere" ]
