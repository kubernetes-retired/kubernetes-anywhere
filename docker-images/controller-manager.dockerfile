FROM temp/hyperkube

ADD controller-manager-anywhere.sh /controller-manager-anywhere
CMD [ "/controller-manager-anywhere" ]
