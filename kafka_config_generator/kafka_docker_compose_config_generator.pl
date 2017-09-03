#!/usr/bin/perl

# run "$ perl ./kafka_docker_compose_config_generator.pl < recipes/sample_cluster3x3.txt"
# or just "$ ./kafka_docker_compose_config_generator.pl < recipes/sample_cluster3x3.txt"
#
# Creates docker-compose yml files, and the script that scp's these files to the Zookeeper and Kafka nodes.
#


# Example of the ConfigRecipe.txt file:
#
# ZOOKEEPER_DOCKER_IMAGE=confluentinc/cp-zookeeper
# ZOOKEEPER_DOCKER_IMAGE_VERSION=3.2.1
# ZOOKEEPER_USERNAME=zkadmin
# ZOOKEEPER_DOCKER_COMPOSE_TEMPLATE=docker-compose-zookeeper.txt
# ZOOKEEPER_NUMBER_OF_NODES=3
# ZOOKEEPER_DOCKER_COMPOSE_FILENAME_BASE=docker-compose-zookeeper
# ZOOKEEPER_HOSTNAME_TEMPLATE=zookeeper\{\{ ZOOKEEPER_NODE_NUMBER \}\}.mydomain.com
# KAFKA_DOCKER_IMAGE=confluentinc/cp-kafka
# KAFKA_DOCKER_IMAGE_VERSION=3.2.1
# KAFKA_USERNAME=kafkaadmin
# DOCKER_COMPOSE_KAFKA_TEMPLATE_FILENAME=templates/docker_compose_kafka_template.txt
# KAFKA_NUMBER_OF_NODES=3
# KAFKA_DOCKER_COMPOSE_FILENAME_BASE=docker-compose-kafka
# KAFKA_HOSTNAME_TEMPLATE=kafka\{\{ KAFKA_NODE_NUMBER \}\}.mydomain.com
# SSH_SERVER_KEY_FOR_UPLOADS="~/mykey4uloads.pem"
# DEPLOYMENT_SCRIPT_FILENAME="~/deploy_kafka.sh"



use strict;
#use warnings FATAL => 'all';
#use warnings;

my %Recipe; # a hash table we load from the file
while (<>)
{
    chomp;
    my ($key, $val) = split /=/;
    # or maybe complain about the duplicates.
    #$Recipe{$key} .= exists $Recipe{$key} ? ",${val}" : "${val}";
    $Recipe{$key} = "${val}";
}

# Put the defaults to the onese not defined.
my $zookeeper_docker_image_base = exists $Recipe{"ZOOKEEPER_DOCKER_IMAGE"} ?
    $Recipe{"ZOOKEEPER_DOCKER_IMAGE"} : "confluentinc/cp-zookeeper";
my $zookeeper_docker_image_version = exists $Recipe{"ZOOKEEPER_DOCKER_IMAGE_VERSION"} ?
    $Recipe{"ZOOKEEPER_DOCKER_IMAGE_VERSION"} : "3.2.1";
my $zookeeper_docker_image = "${zookeeper_docker_image_base}:${zookeeper_docker_image_version}";
my $zookeeper_username= exists $Recipe{"ZOOKEEPER_USERNAME"} ? $Recipe{"ZOOKEEPER_USERNAME"} : "zkadmin";

my $docker_compose_zookeeper_template_filename = exists $Recipe{"ZOOKEEPER_DOCKER_COMPOSE_TEMPLATE"} ?
    $Recipe{"ZOOKEEPER_DOCKER_COMPOSE_TEMPLATE"} : "templates/docker_compose_zookeeper_template.txt";
my $zookeeper_number_of_nodes = exists $Recipe{"ZOOKEEPER_NUMBER_OF_NODES"} ?
    $Recipe{"ZOOKEEPER_NUMBER_OF_NODES"} : "3";
my $zookeeper_docker_compose_filename_base = exists $Recipe{"ZOOKEEPER_DOCKER_COMPOSE_FILENAME_BASE"} ?
    $Recipe{"ZOOKEEPER_DOCKER_COMPOSE_FILENAME_BASE"} : "docker-compose-zookeeper"; # (the numbers will be appended), and then ".yml" 
my $zookeeper_hostname_template = exists $Recipe{"ZOOKEEPER_HOSTNAME_TEMPLATE"} ?
    $Recipe{"ZOOKEEPER_HOSTNAME_TEMPLATE"} : "zookeeper\{\{ ZOOKEEPER_NODE_NUMBER \}\}.mydomain.com";

#print "Creating a set of zookeeper docker-compose files for ${zookeeper_number_of_nodes} nodes.\n";
#print("Zookeeper docker-compose template: ", $docker_compose_zookeeper_template_filename,"\"\n");

my $kafka_docker_image_base = exists $Recipe{"KAFKA_DOCKER_IMAGE"} ?
    $Recipe{"KAFKA_DOCKER_IMAGE"} : "confluentinc/cp-kafka";
my $kafka_docker_image_version = exists $Recipe{"KAFKA_DOCKER_IMAGE_VERSION"} ?
    $Recipe{"KAFKA_DOCKER_IMAGE_VERSION"} : "3.2.1";
my $kafka_docker_image = "${kafka_docker_image_base}:${kafka_docker_image_version}";
my $kafka_username= exists $Recipe{"KAFKA_USERNAME"} ? $Recipe{"KAFKA_USERNAME"} : "kafkaadmin";

my $docker_compose_kafka_template_filename = exists $Recipe{"KAFKA_DOCKER_COMPOSE_TEMPLATE"} ?
    $Recipe{"KAFKA_DOCKER_COMPOSE_TEMPLATE"} : "templates/docker_compose_kafka_template.txt";
my $kafka_number_of_nodes = exists $Recipe{"KAFKA_NUMBER_OF_NODES"} ?
    $Recipe{"KAFKA_NUMBER_OF_NODES"} : "3";
my $kafka_docker_compose_filename_base = exists $Recipe{"KAFKA_DOCKER_COMPOSE_FILENAME_BASE"} ?
    $Recipe{"KAFKA_DOCKER_COMPOSE_FILENAME_BASE"} : "docker-compose-kafka"; # (the numbers will be appended), and then ".yml" 
my $kafka_hostname_template = exists $Recipe{"KAFKA_HOSTNAME_TEMPLATE"} ?
    $Recipe{"KAFKA_HOSTNAME_TEMPLATE"} : "kafka\{\{ KAFKA_NODE_NUMBER \}\}.mydomain.com";

my $deployment_script_filename = exists $Recipe{"DEPLOYMENT_SCRIPT_FILENAME"} ?
    $Recipe{"DEPLOYMENT_SCRIPT_FILENAME"} : "deploy_kafka.sh";

my $ssh_server_key_for_uploads = exists $Recipe{"SSH_SERVER_KEY_FOR_UPLOADS"} ?
    $Recipe{"SSH_SERVER_KEY_FOR_UPLOADS"} : "~/mykey4uloads.pem";

#print "Creating a set of zkafka docker-compose files for ${kafka_number_of_nodes} nodes.\n";
#print("Kafka docker-compose template: ", $docker_compose_kafka_template_filename,"\"\n");

open (my $deployment_script_fh, ">", "output/$deployment_script_filename") or die "Could not open \"output/${deployment_script_filename}\": $!";

print "Creating \"output/${deployment_script_filename}\"\n";

print $deployment_script_fh "#!/usr/bin/env bash\n";

my $i = 0;
my $zookeeper_servers_list_full = "";
my $kafka_zookeeper_connect="";

while($i++ < $zookeeper_number_of_nodes) {
    my $zookeeper_hostname = $zookeeper_hostname_template;
    $zookeeper_hostname=~ s/\{\{ ZOOKEEPER_NODE_NUMBER \}\}/${i}/g;

    $zookeeper_servers_list_full .= $zookeeper_hostname . ":2888:3888";
    $kafka_zookeeper_connect .= $zookeeper_hostname . ":2181";
    
    if($i > 0) {
        $zookeeper_servers_list_full .= ";";
        $kafka_zookeeper_connect .= ",";
    }
}

$i = 0;
while($i++ < $zookeeper_number_of_nodes) {
    open (my $template_file_name_fh, '<:encoding(UTF-8)', $docker_compose_zookeeper_template_filename) or
        die "Could not open \"${docker_compose_zookeeper_template_filename}\": $!";
        
    my $zookeeper_docker_compose_filename = "output/${zookeeper_docker_compose_filename_base}${i}.yml";
      
    open (my $next_fh, ">", $zookeeper_docker_compose_filename) or die "Could not open \"output/${zookeeper_docker_compose_filename}\": $!";

    print "Creating \"output/${zookeeper_docker_compose_filename}\"\n";
    
    my $zookeeper_hostname = $zookeeper_hostname_template;
    $zookeeper_hostname=~ s/\{\{ ZOOKEEPER_NODE_NUMBER \}\}/${i}/g;

    while(my $row=<$template_file_name_fh>) {
            #chomp $row;
            $row =~ s/\{\{ ZOOKEEPER_NODE_NUMBER \}\}/$i/g;
            $row =~ s/\{\{ ZOOKEEPER_DOCKER_IMAGE \}\}/${zookeeper_docker_image}/g;
            $row =~ s/\{\{ ZOOKEEPER_DOCKER_IMAGE_VERSION \}\}/${zookeeper_docker_image_version}/g;
            $row =~ s/\{\{ ZOOKEEPER_USER_NAME \}\}/${zookeeper_username}/g;
            $row =~ s/\{\{ ZOOKEEPER_NODE_HOSTNAME \}\}/${zookeeper_hostname}/g;

            my $zookeeper_servers_list = $zookeeper_servers_list_full;
            $zookeeper_servers_list =~ s/${zookeeper_hostname}/0.0.0.0/g;
            
            $row =~ s/\{\{ ZOOKEEPER_SERVERS_LIST \}\}/${zookeeper_servers_list}/g;

            print $next_fh $row;
    }
    
    print $deployment_script_fh "scp -i ${ssh_server_key_for_uploads} ".
        "${zookeeper_docker_compose_filename_base}${i}.yml ".
        "${zookeeper_username}\@${zookeeper_hostname}:~/${zookeeper_docker_compose_filename_base}${i}.yml".
        "\n";
}
 
$i = 0;
while($i++ < $kafka_number_of_nodes) {
    open (my $template_file_name_fh, '<:encoding(UTF-8)', $docker_compose_kafka_template_filename) or
        die "Could not open \"${docker_compose_kafka_template_filename}\": $!";

    my $kafka_docker_compose_filename = "output/${kafka_docker_compose_filename_base}${i}.yml";
    
    open (my $next_fh, ">", $kafka_docker_compose_filename) or die "Could not open \"output/${kafka_docker_compose_filename}\": $!";

    print "Creating \"output/${kafka_docker_compose_filename}\"\n";
    
    my $kafka_hostname = $kafka_hostname_template;
    $kafka_hostname=~ s/\{\{ KAFKA_NODE_NUMBER \}\}/${i}/g;

    while(my $row=<$template_file_name_fh>) {
        #chomp $row;
        $row =~ s/\{\{ KAFKA_NODE_NUMBER \}\}/$i/g;
        $row =~ s/\{\{ KAFKA_DOCKER_IMAGE \}\}/${kafka_docker_image}/g;
        $row =~ s/\{\{ KAFKA_DOCKER_IMAGE_VERSION \}\}/${kafka_docker_image_version}/g;
        $row =~ s/\{\{ KAFKA_USER_NAME \}\}/${kafka_username}/g;
        $row =~ s/\{\{ KAFKA_NODE_HOSTNAME \}\}/${kafka_hostname}/g;
        $row =~ s/\{\{ KAFKA_ZOOKEEPER_CONNECT \}\}/${kafka_zookeeper_connect}/g;

        print $next_fh $row;
    }
    print $deployment_script_fh "scp -i ${ssh_server_key_for_uploads} ".
        "${kafka_docker_compose_filename_base}${i}.yml ".
        "${kafka_username}\@${kafka_hostname}:~/${kafka_docker_compose_filename_base}${i}.yml".
        "\n";
}

