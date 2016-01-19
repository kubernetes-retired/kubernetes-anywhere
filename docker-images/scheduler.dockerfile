FROM gcr.io/google_containers/hyperkube:v1.1.3
LABEL works.weave.role=system

ADD scheduler-anywhere.sh /scheduler-anywhere
CMD [ "/scheduler-anywhere" ]
