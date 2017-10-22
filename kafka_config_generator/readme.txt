
Generate files like so:

    $ ./kafka_docker_compose_config_generator.pl < recipes/sample_cluster1x1.txt
    Creating "output/deploy_kafka.sh"
    Creating "output/output/docker-compose-zookeeper1.yml"
    Creating "output/output/docker-compose-kafka1.yml"

Once you generated the files, run this to start Zookeeper node:

    $ sudo docker-compose -f output/docker-compose-zookeeper1.yml up -d
    Pulling zookeeper1 (confluentinc/cp-zookeeper:3.2.1)...
    3.2.1: Pulling from confluentinc/cp-zookeeper
    cd0a524342ef: Pull complete
    960ed3547832: Pull complete
    fa281278a626: Pull complete
    e06bb6cb8629: Pull complete
    b45c9e4780b7: Pull complete
    b7abaa40d4a1: Pull complete
    f9f714582c87: Pull complete
    Digest: sha256:56c13e3eb20ed336cd62df5e9bfce275e6da4342872e3ae620099597399f5fcd
    Status: Downloaded newer image for confluentinc/cp-zookeeper:3.2.1
    Creating output_zookeeper1_1 ... 
    Creating output_zookeeper1_1 ... done


On same or different machine run:
    
    $ sudo docker-compose -f output/docker-compose-kafka1.yml up -d    
    Pulling kafka1 (confluentinc/cp-kafka:3.2.1)...
    3.2.1: Pulling from confluentinc/cp-kafka
    cd0a524342ef: Already exists
    960ed3547832: Already exists
    fa281278a626: Already exists
    e06bb6cb8629: Already exists
    b45c9e4780b7: Already exists
    5bd3856619d7: Pull complete
    d6878f2289b9: Pull complete
    Digest: sha256:00a40ca9a0c7f1bcbe66903fb37f390ebc527153ad5d267af213062ea64c2d8f
    Status: Downloaded newer image for confluentinc/cp-kafka:3.2.1
    Creating output_kafka1_1 ... 
    Creating output_kafka1_1 ... done
    
Congrats, you are now running your Kafka and Zookeeper cluster on your machine    

    $ docker ps
    CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS              PORTS               NAMES
    7df506f3f6b4        confluentinc/cp-kafka:3.2.1       "/etc/confluent/do..."   5 minutes ago       Up 5 minutes                            output_kafka1_1
    8ca54a42c013        confluentinc/cp-zookeeper:3.2.1   "/etc/confluent/do..."   5 minutes ago       Up 5 minutes                            output_zookeeper1_1

From where the Kafka bin is:

    $ ./kafka-topics.sh --zookeeper localhost:2181 --create --topic KafkaWorks --replication-factor 1 -partitions 3
    KafkaWorks
    $ ./kafka-topics.sh --zookeeper localhost:2181 --list
    KafkaWorks

Open a couple of terminals, run one as a console-producer, the other one as console-consumer, and see that you can pass the messages around.

    $ ./kafka-console-producer.sh --broker-list localhost:9092 --topic KafkaWorks
    >something
    >

It shows up in a separate terminal (start it before you type anything in the producer terminal)

    $ ./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic KafkaWorks
    something

