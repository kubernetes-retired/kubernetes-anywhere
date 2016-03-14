FROM temp/hyperkube

ADD scheduler-anywhere.sh /scheduler-anywhere
CMD [ "/scheduler-anywhere" ]
