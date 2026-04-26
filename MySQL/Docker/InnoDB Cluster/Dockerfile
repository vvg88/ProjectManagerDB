FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ROOT_PASSWORD=Qwert123

# Update package lists
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    nano \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install MySQL APT repository configuration and key
RUN wget https://dev.mysql.com/get/mysql-apt-config_0.8.28-1_all.deb && \
    dpkg -i mysql-apt-config_0.8.28-1_all.deb && \
    apt-get update --allow-insecure-repositories && \
    rm mysql-apt-config_0.8.28-1_all.deb

# Install MySQL Server and MySQL Shell
RUN apt-get install -y --allow-unauthenticated \
    mysql-server \
    mysql-shell \
    && rm -rf /var/lib/apt/lists/*

# Create MySQL data directory
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose MySQL port
EXPOSE 3306

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
