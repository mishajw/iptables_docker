FROM python:3.6-alpine

RUN \
  apk -U add openssh curl && \
  rm -rf /tmp/* /var/cache/apk/* && \
  for key in rsa dsa ecdsa ed25519; do \
    ssh-keygen -f /etc/ssh/ssh_host_${key}_key -N '' -t ${key}; \
  done && \
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
  echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config && \
  passwd -d root

WORKDIR /var/www
RUN echo "Hello, world!" >> index.html
CMD /usr/sbin/sshd & python -m http.server

