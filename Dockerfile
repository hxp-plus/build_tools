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


# 构建参数
ARG BRANCH
ARG PLATFORM
ARG HTTP_PROXY
ARG HTTPS_PROXY

ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV BRANCH=${BRANCH}
ENV PLATFORM=${PLATFORM}

ENV TAR_OPTIONS=--no-same-owner

# 执行构建命令
CMD cd tools/linux && if [ -n "$BRANCH" ]; then \
        BRANCH_ARG="--branch=${BRANCH}"; \
    else \
        BRANCH_ARG=""; \
    fi && \
    if [ -n "$PLATFORM" ]; then \
        PLATFORM_ARG="--platform=${PLATFORM}"; \
    else \
        PLATFORM_ARG=""; \
    fi && \
    python3 ./automate.py $BRANCH_ARG $PLATFORM_ARG server
