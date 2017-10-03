# fetch base image
FROM osyris/docker-lapis:latest

# install libraries
RUN luarocks install luacrypto  \
    && luarocks install luajwt  \
    && luarocks install uuid    \
    && luarocks install inspect

# setup project
RUN mkdir -p ~/Project/src  \
    && mkdir -p ~/Project/bin
COPY . ~/Project/
RUN cd ~/Project/src        \
    && moonc -t ./../bin .

WORKDIR ~/Project/bin

# run lapis
CMD ["lapis", "server"]