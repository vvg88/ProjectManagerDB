FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and add Percona repository
RUN apt-get update && \
    apt-get install -y \
        curl \
        wget \
        gnupg \
        lsb-release && \
    curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb && \
    apt-get install -y ./percona-release_latest.generic_all.deb && \
    percona-release setup ps-80 && \
    apt-get update && \
    apt-get install -y \
        mysql-server \
        percona-xtrabackup-80 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f percona-release_latest.generic_all.deb

# Create backup directory with proper permissions
RUN mkdir -p /backup && chmod 777 /backup

# Create MySQL run directory
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld && \
    chmod 777 /run/mysqld

# Set MySQL environment variables
ENV MYSQL_ROOT_PASSWORD=Qwert123 \
    MYSQL_DATABASE=project_manager_db

# Expose MySQL port
EXPOSE 3306

# Start MySQL service
CMD ["/bin/bash", "-c", "service mysql start && tail -f /dev/null"]
