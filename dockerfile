# syntax=docker/dockerfile:1.7

FROM golang:1.24-alpine AS builder
WORKDIR /src

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

# 若仓库包含前端静态资源或子目录，按实际目录结构保留即可；
# 若需单独指定子目录入口（如 ./cmd/server），可将下方 "." 改为对应路径
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -trimpath -ldflags="-s -w -X main.Version=${VERSION}" \
    -o /out/cfdata-web .

FROM alpine:3.21 AS runtime
WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata && \
    mkdir -p /app/data /app/config

COPY --from=builder /out/cfdata-web /usr/local/bin/cfdata-web

ENV TZ=Asia/Shanghai
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/cfdata-web"]