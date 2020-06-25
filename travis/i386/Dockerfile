FROM mulle-objc-developer-32:latest

#
# Setup a user named "travis" for running, because why not...
#
RUN \
   apt-get -y install tree curl rsync && \
   useradd -ms /bin/bash travis && \
   adduser travis sudo && \
   echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER travis
WORKDIR /home/travis
COPY run-mulle-sde-project /usr/bin/
ENTRYPOINT [ "/usr/bin/run-mulle-sde-project" ]
CMD [ "/bin/bash" ]
