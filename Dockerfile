FROM ubuntu:18.04

# 设置时区
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 启用 universe 仓库并安装基础工具
RUN apt-get update && \
    apt-get install -y software-properties-common ca-certificates && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y python python3 wget sudo lsb-release gnupg && \
    rm -rf /var/lib/apt/lists/*

# 在 deps.py 之前安装依赖
RUN apt-get update && \
    apt-get install -y \
    autoconf build-essential cmake curl git \
    libglib2.0-dev libglu1-mesa-dev libgtk-3-dev libpulse-dev \
    libtool p7zip-full subversion libasound2-dev libatspi2.0-dev \
    libcups2-dev libdbus-1-dev libicu-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libx11-xcb-dev libxcb1-dev libxi-dev libxrender-dev libxss-dev && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@9.8.1 yarn grunt-cli pkg && \
    rm -rf /var/lib/apt/lists/*

# 添加 LLVM 仓库并安装 clang-12
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y clang-12 lld-12 llvm-12 && \
    rm -rf /var/lib/apt/lists/*


# 工作目录
ADD . /build_tools
WORKDIR /build_tools
# 设置 Python 链接
RUN rm /usr/bin/python && ln -s /usr/bin/python2 /usr/bin/python

ENV BRANCH=v8.1.0.178
ENV PLATFORM=linux_arm64
ENV TAR_OPTIONS=--no-same-owner

# 执行构建命令
RUN cd /build_tools/tools/linux && python3 ./automate.py --branch=${BRANCH} --platform=${PLATFORM} server

# 修改最大连接数到99999后重新构建
RUN sed -i 's/exports.LICENSE_CONNECTIONS = 20;/exports.LICENSE_CONNECTIONS = 99999;/' /server/Common/sources/constants.js
RUN grep LICENSE_CONNECTIONS /server/Common/sources/constants.js
RUN sed -i 's/"--update", "1"/"--update", "0"/' /build_tools/tools/linux/automate.py
RUN cd /build_tools/tools/linux && python3./automate.py --branch=${BRANCH} --platform=${PLATFORM} server 

# 将构建好的二进制拷贝到新镜像
FROM ubuntu:20.04
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
COPY --from=0 /build_tools/out/linux_arm64/onlyoffice/documentserver /var/www/onlyoffice/documentserver
RUN apt-get -y update && apt-get -y install sudo vim ttf-wqy-zenhei fonts-wqy-microhei curl iputils-ping
RUN cd /var/www/onlyoffice/documentserver && \
  mkdir fonts && \
  LD_LIBRARY_PATH=${PWD}/server/FileConverter/bin server/tools/allfontsgen \
  --input="${PWD}/core-fonts" \
  --allfonts-web="${PWD}/sdkjs/common/AllFonts.js" \
  --allfonts="${PWD}/server/FileConverter/bin/AllFonts.js" \
  --images="${PWD}/sdkjs/common/Images" \
  --selection="${PWD}/server/FileConverter/bin/font_selection.bin" \
  --output-web='fonts' \
  --use-system="true" &&  \
  LD_LIBRARY_PATH=${PWD}/server/FileConverter/bin server/tools/allthemesgen \
  --converter-dir="${PWD}/server/FileConverter/bin" \
  --src="${PWD}/sdkjs/slide/themes" \
  --output="${PWD}/sdkjs/common/Images"
CMD [ "/bin/bash" ]
