#!/bin/bash

SERVICE_NAME=$1
RELEASE_VERSION=$2
USER_NAME=$3
EMAIL=$4

git config user.name "$USER_NAME"
git config user.email "$EMAIL"
git fetch --all && git checkout main
git pull origin main
git pull --tags

sudo apt-get install -y protobuf-compiler golang-goprotobuf-dev
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
mkdir -p golang
protoc --go_out=./golang --go_opt=paths=source_relative \
  --go-grpc_out=./golang --go-grpc_opt=paths=source_relative \
 ./${SERVICE_NAME}/*.proto
cd golang/${SERVICE_NAME}
go mod init \
  github.com/OkabeRintarouBeta/microservice-protobuf/golang/${SERVICE_NAME} || true
go mod tidy
cd ../../
git add . && git commit -am "proto update" || true
git push origin HEAD:main
# Check if the tag already exists in the remote repository
if git ls-remote --tags origin | grep "golang/${SERVICE_NAME}/${RELEASE_VERSION}" >/dev/null; then
  echo "Tag golang/${SERVICE_NAME}/${RELEASE_VERSION} already exists. Skipping tag creation."
else
  # Create and push the tag if it doesn't exist
  git tag -a "golang/${SERVICE_NAME}/${RELEASE_VERSION}" -m "golang/${SERVICE_NAME}/${RELEASE_VERSION}"
  git push origin "refs/tags/golang/${SERVICE_NAME}/${RELEASE_VERSION}"
fi
git push origin refs/tags/golang/${SERVICE_NAME}/${RELEASE_VERSION} --force
