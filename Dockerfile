# Copyright 2024 Thoughtworks, Inc.
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

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM curlimages/curl:latest AS gocd-agent-unzip
USER root
ARG TARGETARCH
ARG UID=1000
RUN curl --fail --location --silent --show-error "https://download.gocd.org/binaries/24.3.0-19261/generic/go-agent-24.3.0-19261.zip" > /tmp/go-agent-24.3.0-19261.zip && \
    unzip -q /tmp/go-agent-24.3.0-19261.zip -d / && \
    mkdir -p /go-agent/wrapper /go-agent/bin && \
    mv -v /go-agent-24.3.0/LICENSE /go-agent/LICENSE && \
    mv -v /go-agent-24.3.0/*.md /go-agent && \
    mv -v /go-agent-24.3.0/bin/go-agent /go-agent/bin/go-agent && \
    mv -v /go-agent-24.3.0/lib /go-agent/lib && \
    mv -v /go-agent-24.3.0/logs /go-agent/logs && \
    mv -v /go-agent-24.3.0/run /go-agent/run && \
    mv -v /go-agent-24.3.0/wrapper-config /go-agent/wrapper-config && \
    WRAPPERARCH=$(if [ $TARGETARCH == amd64 ]; then echo x86-64; elif [ $TARGETARCH == arm64 ]; then echo arm-64; else echo $TARGETARCH is unknown!; exit 1; fi) && \
    mv -v /go-agent-24.3.0/wrapper/wrapper-linux-$WRAPPERARCH* /go-agent/wrapper/ && \
    mv -v /go-agent-24.3.0/wrapper/libwrapper-linux-$WRAPPERARCH* /go-agent/wrapper/ && \
    mv -v /go-agent-24.3.0/wrapper/wrapper.jar /go-agent/wrapper/ && \
    chown -R ${UID}:0 /go-agent && chmod -R g=u /go-agent

FROM docker.io/ubuntu:jammy
ARG TARGETARCH

LABEL gocd.version="24.3.0" \
  description="GoCD agent based on docker.io/ubuntu:jammy" \
  maintainer="GoCD Team <go-cd-dev@googlegroups.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="24.3.0-19261" \
  gocd.git.sha="3d8bed12557f0b310a4bce58f076abbfc2841ae9"

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-${TARGETARCH} /usr/local/sbin/tini

# force encoding
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  DEBIAN_FRONTEND=noninteractive apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
  (userdel --remove --force ubuntu || true) && \
  useradd -l -u ${UID} -g root -d /home/go -m go && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y git-core openssh-client bash unzip curl ca-certificates locales procps coreutils && \
  DEBIAN_FRONTEND=noninteractive apt-get clean all && \
  rm -rf /var/lib/apt/lists/* && \
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
  curl --fail --location --silent --show-error "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jre_$(uname -m | sed -e s/86_//g)_linux_hotspot_21.0.4_7.tar.gz" --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-agent /docker-entrypoint.d /go /godata

ADD docker-entrypoint.sh /


COPY --from=gocd-agent-unzip /go-agent /go-agent
# ensure that logs are printed to console output
COPY --chown=go:root agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xml /go-agent/config/

RUN chown -R go:root /docker-entrypoint.d /go /godata /docker-entrypoint.sh && \
    chmod -R g=u /docker-entrypoint.d /go /godata /docker-entrypoint.sh


ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
