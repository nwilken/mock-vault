FROM vault:latest
LABEL maintainer="Nate Wilken <wilken@asu.edu>"

RUN apk --update add --no-cache bash jq
    
COPY entrypoint-wrapper.sh /usr/local/bin/entrypoint-wrapper.sh
ENTRYPOINT ["entrypoint-wrapper.sh"]
