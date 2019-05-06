#! /usr/bin

# date:2019-05-06
# author:sunbin

# 安装依赖库
yum -y install autoconf  automake libtool  curl  make  g++  unzip  gmock

#克隆protobuf源码
git clone git@github.com:protocolbuffers/protobuf.git

cd protobuf


# Check that gtest is present.  Usually it is already there since the
# directory is set up as an SVN external.
# 判断是否存在gtest目录
if test ! -e gtest; then
  echo "Google Test not present.  Fetching gtest-1.5.0 from the web..."
  #如果目录不存在则尝试从google.com下载并解压缩，如果google被墙则下载失败
  git clone git@github.com:google/googletest.git
  #将解压缩后的目录改名为gtest
  mv googletest ./third_party/gtest
fi

#生成configure文件
sh autogen.sh
sh configure
make && make check

# 安装完成之后，会在 /usr/lib 目录下生成前缀为 libprotobuf, libprotobuf-lite, libprotoc 
# 这三类静态和动态库文件。
make install

# ldconfig 来更新 lib 路径
ldconfig

# 如果上述步骤完成之后，执行 protoc 时仍发生错误的话，我们可以按如下方式手动链接
# ln -s /usr/lib/libprotobuf.so.10.0.0 /usr/lib/libprotobuf.so
