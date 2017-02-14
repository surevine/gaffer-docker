##########################################################
# Copyright 2016 Crown Copyright, cybermaggedon
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################

GAFFER_VERSION=0.6.1

REPOSITORY=docker.io/gchq/gaffer

NS_PREFIX=uk/gov/gchq/

VERSION=${GAFFER_VERSION}

SUDO=

PROXY_ARGS=--build-arg HTTP_PROXY=${http_proxy} --build-arg http_proxy=${http_proxy} --build-arg HTTPS_PROXY=${https_proxy} --build-arg https_proxy=${https_proxy}

PROXY_HOST_PORT_ARGS=--build-arg proxy_host=${proxy_host} --build-arg proxy_port=${proxy_port}

all: build container

product:
	mkdir product

# In the future this could be removed when the Gaffer binaries are published to Maven Central.
build: product
	rm -rf repository product
	${SUDO} docker build ${PROXY_ARGS} ${PROXY_HOST_PORT_ARGS} ${BUILD_ARGS} --build-arg GAFFER_VERSION=${GAFFER_VERSION} -t gaffer-build -f Dockerfile.build .
	id=$$(${SUDO} docker run -d gaffer-build sleep 3600); \
	dir=/root/.m2/repository; \
	${SUDO} docker cp $${id}:$${dir} .; \
	${SUDO} docker rm -f $${id}
	mkdir product
	for stuff in `find repository/${NS_PREFIX} -\( -name '*.jar' -or -name '*.war' -\) -not -name '*tests*'`; do \
	    tgt=$$(basename $$stuff); \
	    cp $$stuff product/$$tgt; \
	done
	rm -rf repository
	rm -rf product/rest-api*.war

container: wildfly-10.1.0.CR1.zip
	${SUDO} docker build ${PROXY_ARGS} ${BUILD_ARGS} -t gaffer -f Dockerfile.deploy .
	${SUDO} docker tag gaffer ${REPOSITORY}:${VERSION}

wildfly-10.1.0.CR1.zip:
	wget download.jboss.org/wildfly/10.1.0.CR1/wildfly-10.1.0.CR1.zip

push:
	${SUDO} docker push ${REPOSITORY}:${VERSION}

