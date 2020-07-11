FROM centos:7.6.1810
MAINTAINER sunhao
# 环境配置(jdk,yarn,nginx,derby)
RUN mkdir /usr/local/java
ADD jdk-8u251-linux-x64.tar.gz /usr/local/java
WORKDIR /opt/
RUN ln -s /usr/local/java/jdk1.8.0_251 /usr/local/java/jdk
ENV LANG en_US.UTF-8
ENV JAVA_HOME /usr/local/java/jdk
ENV JRE_HOME $JAVA_HOME/jre
ENV CLASSPATH .:${JAVA_HOME}/lib:${JRE_HOME}/lib 
ENV PATH ${JAVA_HOME}/bin:$PATH 
ENV ELASTIC_HOSTS="192.168.0.121:9200"
ENV ELASTIC_USER="elastic"
ENV ELASTIC_PASSWORD="Passc0de@tp"
ENV KIBANA_URL="http://192.168.0.121:5601"
ENV ANSIBLE_HOST="localhost"
ENV ANSIBLE_USER="root"
ENV ANSIBLE_PSW="Passc0de@tp"
COPY web/ /opt/web/
COPY db-derby-10.14.2.0-bin/ ./db-derby-10.14.2.0-bin/
RUN yum install -y epel-release &> /dev/null;\
	yum install -y nginx &> /dev/null;\
	yum install -y gettext &> /dev/null;\
	curl -O https://nodejs.org/dist/v12.18.1/node-v12.18.1-linux-x64.tar.xz && tar -xvf node-v12.18.1-linux-x64.tar.xz &> /dev/null;\
	echo "export PATH=$PATH:/opt/node-v12.18.1-linux-x64/bin" >> /etc/profile;\
	source /etc/profile;\
	curl -o /etc/yum.repos.d/yarn.repo https://dl.yarnpkg.com/rpm/yarn.repo;\
	curl --silent --location https://rpm.nodesource.com/setup_12.x | bash - &> /dev/null;\
	yum install yarn -y &> /dev/null;\
	echo fs.inotify.max_user_watches = 524288 | tee -a /etc/sysctl.conf;\
	rm -f node-v12.18.1-linux-x64.tar.xz;\
	cd /opt/web/ && yarn install &> /dev/null

# 后端代码
COPY application.yaml /opt/config/
ADD loganalysis-1.0.0-SNAPSHOT.jar /opt/app.jar
# nginx代理配置
COPY nginx.template /etc/nginx/
RUN envsubst '${KIBANA_URL}' < /etc/nginx/nginx.template > /etc/nginx/nginx.conf
COPY certificate /etc/nginx/certificate/
# 新建ansible用户
RUN useradd --create-home --no-log-init --shell /bin/bash ansible_user
RUN echo 'root:Passc0de@tp' | chpasswd
RUN mkdir -p /home/filebeat/modules

COPY startup.sh .
ENTRYPOINT ["sh","startup.sh"]	
