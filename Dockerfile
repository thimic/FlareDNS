
FROM swift

WORKDIR /etc/opt/FlareDNS

COPY ./ ./

ENV FLAREDNS_CONFIG "/config"
ENV PATH "/etc/opt/FlareDNS/bin:${PATH}"

RUN swift build -c release

RUN mkdir bin && \
    cp .build/release/FlareDNS bin/ && \
    chmod +x bin/FlareDNS

VOLUME [ "/config" ]

CMD ["FlareDNS"]