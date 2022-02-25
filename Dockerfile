# Container image that runs your code
FROM alpine:3.15

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x wait-for-it.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/wait-for-it.sh"]