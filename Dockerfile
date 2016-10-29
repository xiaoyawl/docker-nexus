FROM benyoo/alpine:8-jdk-alpine
MAINTAINER from www.dwhd.org by lookback (mondeolove@gmail.com)

ARG VERSION=3.0.2-02
ARG BUILD_LOACL=${BUILD_LOACL:-no}
ARG LOACL_DOWN=${LOACL_DOWN:-http://mirrors.ds.com/tar%E5%8C%85}
ENV INSTALL_DIR=/usr/local/nexus \
	DATA_DIR=/data/nexus \
	NEXUS_CONTEXT=''

RUN set -x && \
	DOWNLOAD=https://download.sonatype.com/nexus && \
	DOWNLOAD=${DOWNLOAD}/${VERSION%%.*} && \
	DOWNLOAD=${DOWNLOAD}/nexus-${VERSION}-unix.tar.gz && \
	if [[ "${BUILD_LOACL}" == "yes" ]]; then DOWNLOAD=${LOACL_DOWN}/nexus-${VERSION}-unix.tar.gz; fi && \
	mkdir -p ${INSTALL_DIR} $(dirname $DATA_DIR) && \
	apk --update --no-cache upgrade && \
	apk --update --no-cache add curl tar && \
	curl -Lk "${DOWNLOAD}"|tar xz -C ${INSTALL_DIR} --strip-components=1 && \
	chown -R root:root ${INSTALL_DIR} && \
	sed -e "s|karaf.home=.|karaf.home=${INSTALL_DIR}|g" \
		-e "s|karaf.base=.|karaf.base=${INSTALL_DIR}|g" \
		-e "s|karaf.etc=etc|karaf.etc=${INSTALL_DIR}/etc|g" \
		-e "s|java.util.logging.config.file=etc|java.util.logging.config.file=${INSTALL_DIR}/etc|g" \
		-e "s|karaf.data=data|karaf.data=${DATA_DIR}|g" \
		-e "s|java.io.tmpdir=data/tmp|java.io.tmpdir=${DATA_DIR}/tmp|g" \
		-i ${INSTALL_DIR}/bin/nexus.vmoptions && \
	sed -e "s|nexus-context-path=/|nexus-context-path=/\${NEXUS_CONTEXT}|g" \
		-i ${INSTALL_DIR}/etc/org.sonatype.nexus.cfg && \
	addgroup -S -g 400 nexus && adduser -S -u 400 -h ${DATA_DIR} -s /sbin/nologin -G nexus nexus && \
	chown -R nexus.nexus ${DATA_DIR}

VOLUME ${DATA_DIR}

EXPOSE 8081
USER nexus
WORKDIR ${DATA_DIR}

ENV JAVA_MAX_MEM=1200m \
	JAVA_MIN_MEM=1200m \
	EXTRA_JAVA_OPTS="" \
	PATH=${INSTALL_DIR}/bin:$PATH

CMD ["nexus", "run"]
