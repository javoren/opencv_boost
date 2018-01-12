FROM centos

RUN yum -y install initscripts MAKEDEV

# SSHサーバ
RUN yum -y install openssh-server
RUN sed -ri 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'root:root' | chpasswd
RUN /usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
RUN /usr/bin/ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -C '' -N ''
RUN /usr/bin/ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -C '' -N ''

# 開発ツール
RUN yum groupinstall -y 'Development tools'
RUN yum install -y git wget cmake
RUN yum install -y sudo

# dockerコンテナとホスト間での共有ディレクトリ
RUN mkdir /tmp/data -p

# boost dl
#RUN wget http://sourceforge.net/projects/boost/files/boost/1.50.0/boost_1_50_0.tar.gz
#RUN tar xvf boost_1_50_0.tar.gz;
RUN wget https://dl.bintray.com/boostorg/release/1.66.0/source/boost_1_66_0.tar.gz
RUN cd /; tar xvf boost_1_66_0.tar.gz

# build boost
RUN cd /boost_1_66_0; ./bootstrap.sh
RUN cd /boost_1_66_0; ./b2 install; exit 0
#RUN cd /boost_1_66_0; ./b2 install
# ./b2 install cxxflags="-std=c++0x"


# OpenCV clone
RUN git clone https://github.com/opencv/opencv.git /root/opencv
RUN git clone https://github.com/opencv/opencv_contrib.git /root/opencv_contrib

# build opencv
RUN cd /root/opencv/; git checkout -b 3.4.0 3.4.0 ;
RUN mkdir /root/opencv/build; cd /root/opencv/build; cmake -D OPENCV_EXTRA_MODULES_PATH=/root/opencv_contrib/modules ..
RUN cd /root/opencv/build; make j5; make install;

# PKG_CONFIG_PATH : ライブラリとヘッダのパスをpkg-configで探せるようにする
# LD_LIBRARY_PATH : 実行時にsoを探せるようにする
RUN echo -e "\
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig\n\
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64\n\
" >> /root/.bashrc

# 共有ディレクトリの準備
RUN mkdir -p /tmp/data

# 起動オプション。CMDに指定できるのは一つだけ。
EXPOSE 22
CMD bash -c "/usr/sbin/sshd -D"

# デフォルトマシンではディスク容量が小さすぎて失敗することがあるので、大きなディスクを用意する
# docker-machine rm default
# docker-machine create -d virtualbox --virtualbox-disk-size 80000 default

# dockerfileをもとにビルドして、イメージを生成する
# docker build -t cv_test .

# 起動
# イメージをコンテナとして実行するdockertools(Win7)をインストール時に共有ディレクトリとして設定されているパスをゲストと共有する。
# docker run -i -t --name cv_test --rm -v /c/Users:/tmp/data　-p 30001:22 -d cv_test

# 停止
# docker stop test
