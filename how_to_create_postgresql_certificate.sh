# Access the kong db directory and follow the steps below. E.x.: /opt/devops/kong/postgresql/kong-db/ 
mkdir certs/ && chmod 700 certs/

# Create a self-signed certificate. The CN is the database address. E.x.: the database container name.
# OBS: The openssl.cnf path is on CentOS 7 .For another distributions, check the correct path.
openssl req -new -nodes -text -out server.csr \
  -keyout server.key -subj "/CN=kong.db.com.br"

openssl x509 -req -in server.csr -text -days 36500 \
  -extfile /etc/pki/tls/openssl.cnf -extensions v3_ca \
  -signkey server.key -out server.crt

# Use it as the root (only for self-signed certificates)
cp server.crt root.crt

# Create the client certificate and sign it with root. The CN is the database username.
openssl req -new -nodes -text -out client.csr \
  -keyout client.key -subj "/CN=kong"

openssl x509 -req -in client.csr -text -days 36500 \
  -CA root.crt -CAkey server.key -CAcreateserial \
  -out client.crt

# Fix permissions - use the username:groupname according with the container user:group
chown 70:70 root.* server.* client.*
chmod 600 root.* server.* client.*

# Move root.crt, server.crt and server.key to certs/ folder
mv root.crt server.crt server.key certs/

# Copy certs/root.crt to client computer/container and move client.crt and client.key to client computer/container
cp certs/root.crt client/folder/path/ && mv client.crt client.key client/folder/path/

# FIX for dbeaver
openssl pkcs8 -topk8 -inform PEM -outform DER -in client.key -out client.pk8 -nocrypt