FROM golang:1.18-alpine
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

WORKDIR /src
COPY . .
RUN go mod download
RUN go mod tidy
RUN go build -o /hello-app

FROM --platform=linux/amd64 alpine:latest
COPY --from=0 /hello-app .
ENV PORT 8080
CMD ["/hello-app"]