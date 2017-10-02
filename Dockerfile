# fetch base image
FROM osyris/docker-lapis:latest

# install libraries
RUN luarocks install luacrypto  \
    && luarocks install luajwt  \
    && luarocks install uuid    \
    && luarocks install inspect

# setup project
COPY ./bin /opt/openresty/nginx/conf
EXPOSE 80