# KAFKA INSTALLER:
# downloads, un-tars, moves to /usr/local, simlinks from full versioned name
# to kafka, exports into path in `.bash_profile`, and then starts
# zookeeper and kafka server

brew install sbt # ensure sbt is installed first!

# current kafka for scala 2.11: http://apache.spd.co.il/kafka/0.8.2.1/kafka_2.11-0.8.2.1.tgz

SCALA_VERSION="2.11"
KAFKA_VERSION="0.8.2.1"
KAFKA_VERSIONED_NAME="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
APACHE_DOWNLOAD_BASEPATH="http://apache.spd.co.il/kafka"
KAFKA_DOWNLOAD_URL="${APACHE_DOWNLOAD_BASEPATH}/${KAFKA_VERSION}/${KAFKA_VERSIONED_NAME}.tgz"

echo "DOWNLOAD URL"
echo "${KAFKA_DOWNLOAD_URL}"

cd /tmp

wget "${KAFKA_DOWNLOAD_URL}"
tar -zxvf "${KAFKA_VERSIONED_NAME}.tgz" -C /usr/local/
cd "/usr/local/${KAFKA_VERSIONED_NAME}"

sbt update
sbt package

cd /usr/local
ln -s "${KAFKA_VERSIONED_NAME}" kafka

echo "" >> ~/.bash_profile
echo "" >> ~/.bash_profile
echo "# KAFKA" >> ~/.bash_profile
echo "export KAFKA_HOME=/usr/local/kafka" >> ~/.bash_profile
source ~/.bash_profile

echo "export KAFKA=$KAFKA_HOME/bin" >> ~/.bash_profile
echo "export KAFKA_CONFIG=$KAFKA_HOME/config" >> ~/.bash_profile
source ~/.bash_profile
