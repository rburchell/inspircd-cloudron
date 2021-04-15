FROM cloudron/base:3.0.0
# FROM cloudron/base:2.0.0@sha256:f9fea80513aa7c92fe2e7bf3978b54c8ac5222f47a9a32a7f8833edf0eb5a4f4

RUN apt update && apt install -y libtre5 gnutls-bin && apt clean -y
RUN wget --progress dot --output-document inspircd.deb https://github.com/inspircd/inspircd/releases/download/v3.9.0/inspircd_3.9.0.ubuntu20.04.2_amd64.deb && \
    dpkg -i inspircd.deb && \
    rm inspircd.deb

RUN mkdir -p /app/data /app/pkg
WORKDIR /app/code
COPY ./pkg /app/pkg

CMD [ "/app/pkg/start.sh" ]
