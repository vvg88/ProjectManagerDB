#!/bin/bash
set -e

# Initialize MySQL data directory if it doesn't exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MySQL data directory..."
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

# Generate unique server UUID for this instance
if [ ! -f "/var/lib/mysql/auto.cnf" ]; then
    echo "Generating unique server UUID..."
    UUID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 8 | head -n 1)
    UUID="${UUID}-$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 4 | head -n 1)"
    UUID="${UUID}-$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 4 | head -n 1)"
    UUID="${UUID}-$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 4 | head -n 1)"
    UUID="${UUID}-$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 12 | head -n 1)"
    
    cat > /var/lib/mysql/auto.cnf <<EOF
[mysqld]
server-uuid=$UUID
EOF
    chown mysql:mysql /var/lib/mysql/auto.cnf
    chmod 644 /var/lib/mysql/auto.cnf
    echo "Generated UUID: $UUID"
fi

# Create supervisor log directory
mkdir -p /var/log/supervisor

# Start mysqld in background to configure permissions
echo "Starting mysqld for configuration..."
mysqld --user=mysql &
MYSQLD_PID=$!

# Wait for MySQL to be ready
echo "Waiting for MySQL to start..."
for i in {1..30}; do
    if mysqladmin ping -h localhost -u root 2>/dev/null; then
        echo "MySQL is ready!"
        break
    fi
    echo "Waiting for MySQL... attempt $i/30"
    sleep 1
done

# Configure root user permissions
echo "Configuring root user permissions..."
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

echo "MySQL cluster configuration complete!"

# Stop mysqld and restart in foreground
echo "Stopping mysqld..."
kill $MYSQLD_PID
wait $MYSQLD_PID 2>/dev/null || true

# Start mysqld in foreground
echo "Starting mysqld in foreground..."
exec mysqld --user=mysql
