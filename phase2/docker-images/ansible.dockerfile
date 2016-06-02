FROM ubuntu:xenial

RUN apt-get -qq update && apt-get -qq --yes install ansible python-boto

RUN apt-get -qq --yes install vim

ADD ansible /src

CMD [ "ansible-playbook", "--inventory-file=/src/inventory", "--connection=chroot", "/src/main.yml" ]
