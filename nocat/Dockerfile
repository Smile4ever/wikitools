FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
curl openssl jq wget

WORKDIR /home/nocat

COPY nocat.sh ./
COPY nocat.log ./
COPY config/username.txt ./config/username.txt
COPY config/password.txt ./config/password.txt

RUN mkdir data/
RUN chmod a+rwx -R data/

CMD ["./nocat.sh"]
