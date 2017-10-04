# fetch base image
FROM osyris/docker-lapis:latest

# install libraries
RUN luarocks install luacrypto  \
    && luarocks install luajwt  \
    && luarocks install uuid    \
    && luarocks install inspect

# setup project
RUN mkdir -p /Project/src       \
    && mkdir -p /Project/bin
COPY ./bin /Project/bin
COPY ./src /Project/src
RUN cd /Project/src             \
    && moonc -t /Project/bin .  \
    && cd /Project/bin          \
    && chmod +x /Project/bin/wait-for-it.sh

WORKDIR /Project/bin
EXPOSE 80

# run lapis
CMD nohup sh -c "cd /Mount/src && moonc -w -t /Project/bin . >> /dev/null &" \
    && lapis server $LAPIS_ENV