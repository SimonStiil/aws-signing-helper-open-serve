FROM alpine:3.23.4 AS base
WORKDIR /app
RUN apk add --no-cache bash libc6-compat 

FROM golang:1.26.2-alpine AS builder
WORKDIR /app
RUN apk add --no-cache make git bash gcc musl-dev && \
    git clone --branch v1.8.2 --depth 1 https://github.com/aws/rolesanywhere-credential-helper.git . && \
    sed -i 's|fmt.Sprintf("%s:%d", LocalHostAddress, endpoint.PortNum)|fmt.Sprintf("%s:%d", "", endpoint.PortNum)|' aws_signing_helper/serve.go && \
    sed -i 's|log.Println("Local server started on port:"|log.Println("Local(patched) server started on port:"|' aws_signing_helper/serve.go && \
    make release

FROM base
WORKDIR /usr/local/bin
COPY --from=builder /app/build/bin/aws_signing_helper /usr/local/bin/aws_signing_helper
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
