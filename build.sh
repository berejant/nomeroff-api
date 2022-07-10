#!/usr/bin/env bash
VERSION=$1

TEST_IMAGE_URL="https://raw.githubusercontent.com/ria-com/nomeroff-net/v3.1.0/data/examples/oneline_images/example1.jpeg"
TEST_IMAGE_EXPECTED="AC4921CB"

VERSIONS=$(
   git ls-remote --tags https://github.com/ria-com/nomeroff-net.git | awk '{print $2}' | sed -e "s/^refs\/tags\/v//"
)

if [ -z "${VERSION}" ]; then
  PS3="Choose version of nomeroff-api by enter number: "
  select VERSION in $VERSIONS
  do
      break
  done
fi

VERSION_EXIST=0
for v in $VERSIONS; do
    if [ $v = "$VERSION" ]; then
        VERSION_EXIST=1
    fi
done

if [ $VERSION_EXIST == 0 ]; then
  echo "Version ${VERSION} doesn't exist"
  exit 1
fi;

export DOCKER_BUILDKIT=1
docker build --pull \
  --build-arg VERSION=${VERSION} \
  --build-arg TEST_IMAGE_URL=${TEST_IMAGE_URL} \
  --build-arg TEST_IMAGE_EXPECTED=${TEST_IMAGE_EXPECTED} \
  -t berejant/nomeroff-api:v${VERSION} . || exit $?

echo 'Image built done';

#
echo "Test container";

TEST_HTTP_PORT=28322
CONTAINER_ID=$(docker run -p ${TEST_HTTP_PORT}:8080 -d --rm berejant/nomeroff-api:v${VERSION})
echo "Container started: ${CONTAINER_ID}"


echo 'Waiting for load container and inner http server...'
for i in 1 2 3 4 5; do
  docker logs ${CONTAINER_ID} 2>&1 | tail -n 5 | grep -q "HTTP Server started" && break || sleep 5 ;
done
echo 'Container and http server loaded'

curl -I -s --output /dev/null \
  --connect-timeout 5 --retry 3 --retry-delay 3 --retry-connrefused http://localhost:${TEST_HTTP_PORT} && \
curl --fail -s ${TEST_IMAGE_URL} | \
curl -X POST -s --data-binary @- http://localhost:${TEST_HTTP_PORT} | grep -q "${TEST_IMAGE_EXPECTED}"

TEST_RESULT=$?

docker stop -t 5 "${CONTAINER_ID}" > /dev/null

# End container Conteiner test end.
if [ ${TEST_RESULT} -ne 0 ]; then
    echo "Container test failed!";
    exit 11;
else
    echo "Container test passed. Push container image to repo"
    docker push berejant/nomeroff-api:v${VERSION} || exit $?
    echo 'Build and push Done!'
fi
