FROM ruby:2.3-alpine

ENV BUILD_PACKAGES build-base gcc
# unzip provides funzip, which allows for streaming zip decompression (of zip's with only 1 file)
ENV RUNTIME_PACKAGES unzip

# Default region, if none supplied (required for AWS SDK)
ENV AWS_REGION us-east-1

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN apk --update add $BUILD_PACKAGES $RUNTIME_PACKAGES && \
    rm -rf .git* && \
    bundle install --without test && \
    apk del $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

CMD rake start;
