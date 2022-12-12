FROM alpine:3.17

# Create app directory
WORKDIR /usr/src

# Add support for bash
RUN apk add --no-cache \
    bash

# Add wait-for-it.sh to check connection to other container
ADD https://raw.githubusercontent.com/Safe-Security/wait-for-it/master/wait-for-it.sh /usr/src/
RUN chmod +x /usr/src/wait-for-it.sh


# Expose wait-for-it.sh script
ENTRYPOINT ["/usr/src/wait-for-it.sh"]