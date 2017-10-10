FROM debian:jessie-slim

ENV OTP_VERSION="20.1.1"
ENV MONO_VERSION 5.2.0.224

# We'll install the build dependencies, and purge them on the last step to make
# sure our final image contains only what we've just built:
RUN set -xe \
	&& OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
	&& OTP_DOWNLOAD_SHA256="1f997c0c8aaa6217dcfc1dc0901717438cb2b63d4c20191f0d3d5c1bf61d4d5c" \
	&& fetchDeps=' \
		curl \
		ca-certificates' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $fetchDeps \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
	&& runtimeDeps=' \
		libodbc1 \
		libssl1.0.0 \
		libsctp1 \
	' \
	&& buildDeps=' \
		autoconf \
		dpkg-dev \
		gcc \
		g++ \
		make \
		libncurses-dev \
		unixodbc-dev \
		libssl-dev \
		libsctp-dev \
	' \
	&& apt-get install -y --no-install-recommends $runtimeDeps \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
	&& export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
	&& mkdir -vp $ERL_TOP \
	&& tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
	&& rm otp-src.tar.gz \
	&& ( cd $ERL_TOP \
	  && ./otp_build autoconf \
	  && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	  && ./configure --build="$gnuArch" \
	  && make -j$(nproc) \
	  && make install ) \
	&& find /usr/local -name examples | xargs rm -rf \
	&& apt-get purge -y --auto-remove $buildDeps $fetchDeps \
	&& rm -rf $ERL_TOP /var/lib/apt/lists/*

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

RUN echo "deb http://download.mono-project.com/repo/debian jessie/snapshots/$MONO_VERSION main" > /etc/apt/sources.list.d/mono-official.list \
  && apt-get update \
  && apt-get install -y mono-runtime \
  && rm -rf /var/lib/apt/lists/* /tmp/*

CMD ["erl"]