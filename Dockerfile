FROM golang:latest AS build

WORKDIR /go
COPY . .

RUN go get -u github.com/gin-gonic/gin
RUN go build -o /bin/app

ENTRYPOINT ["/bin/app"]