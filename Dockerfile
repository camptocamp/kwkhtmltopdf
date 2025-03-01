# first stage: build kwkhtmltopdf_server

FROM golang:1.21.5
RUN mkdir /tmp/kwkhtml
WORKDIR /tmp/kwkhtml
COPY server/kwkhtmltopdf_server.go .
RUN go mod init kwkhtml
RUN go get -u github.com/rs/zerolog/log@v1.31.0
RUN go get -u github.com/pkg/errors@v0.9.1

RUN go build kwkhtmltopdf_server.go

# second stage: server with wkhtmltopdf

FROM debian:bookworm-slim 

RUN set -x \
  && apt update \
  && apt -y install --no-install-recommends wget ca-certificates fonts-liberation2 fonts-nanum-coding fonts-horai-umefont fonts-wqy-microhei \  
  && wget -q -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
  && echo "e9f95436298c77cc9406bd4bbd242f4771d0a4b2 /tmp/wkhtmltox.deb" | sha1sum -c - \
  && apt -y install /tmp/wkhtmltox.deb \
  && apt -y purge wget --autoremove \
  && apt -y clean \
  && rm -rf /var/lib/apt/lists/*
COPY --from=0 /tmp/kwkhtml/kwkhtmltopdf_server /usr/local/bin/

RUN adduser --disabled-password --gecos '' kwkhtmltopdf
USER kwkhtmltopdf
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

EXPOSE 8080
CMD /usr/local/bin/kwkhtmltopdf_server
