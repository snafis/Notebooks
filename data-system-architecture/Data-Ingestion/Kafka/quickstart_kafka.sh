# Step 1: Start the Zookeeper server
####################################
# Kafka uses ZooKeeper so you need to first start a ZooKeeper server if you don't already have one. You can use the convenience script 
# packaged with kafka to get a quick-and-dirty single-node ZooKeeper instance.

osascript -e 'tell app "Terminal"
    do script "$KAFKA/zookeeper-server-start.sh $KAFKA_CONFIG/zookeeper.properties"
end tell'

# Step 2: Start the Kafka server
################################
# Now start the Kafka server:

osascript -e 'tell app "Terminal"
    do script "$KAFKA/kafka-server-start.sh $KAFKA_CONFIG/server.properties"
end tell'

# Step 3: Create a topic
########################
# Let's create a topic named "test" with a single partition and only one replica:

osascript -e 'tell app "Terminal"
    do script "$KAFKA/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test; $KAFKA/kafka-topics.sh --list --zookeeper localhost:2181"
end tell'

# We can now see that topic from the list topic command output
# test

# Alternatively, instead of manually creating topics you can also configure your brokers to auto-create topics when a non-existent topic is published to.

# Step 4: Start a Producer
############################
# Kafka comes with a command line client that will take input from a file or from standard input and send it out as messages to the  
# Kafka cluster. By default each line will be sent as a separate message.
# Run the producer and then type a few messages into the console to send to the server.

osascript -e 'tell app "Terminal"
    do script "$KAFKA/kafka-console-producer.sh --broker-list localhost:9092 --topic test"
end tell'


# Step 5: Start a consumer
##########################
# Kafka also has a command line consumer that will dump out messages to standard output.

osascript -e 'tell app "Terminal"
    do script "$KAFKA/kafka-console-consumer.sh --zookeeper localhost:2181 --topic test --from-beginning"
end tell'

# Now test the messaging pipeline by typing some test message in the Producer Terminal and see it appear in the Consumer Terminal
# This is a message
# This is another message
