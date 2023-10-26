# Default Variables
## All

### Environment

```yaml
infra_env: "{{ lookup('env', 'ENVIRONMENT') | default('production') }}"
```
### Username of the user owning the files

```yaml
infra_user_name: "{{ svc_user_name }}"
```
### Group name of the group that should own the files

```yaml
infra_group_name: "{{ svc_group_name }}"
```
### Optionally provide the UID of the user. If absent, the UID will be looked up

```yaml
infra_user_uid: "{{ svc_user_uid }}"
```
### Optionally provide the GID of the group. If absent, the GID will be looked up

```yaml
infra_group_gid: "{{ svc_group_gid }}"
```
### Timezone

```yaml
infra_tz: Etc/UTC
```
### Domain name, internal

```yaml
infra_domain: "{{ svc_domain }}"
```
### Domain name, external

```yaml
infra_domain_ext: ~
```
## Directories

### Manage directories

```yaml
infra_manage_directories: true
```
### Directory to store service data

```yaml
infra_directory_path: '/opt/infra'
```
### Default permissions

```yaml
infra_directory_owner: "{{ infra_user_name }}"
```
```yaml
infra_directory_group: "{{ infra_group_name }}"
```
```yaml
infra_directory_mode: 740
```
### Subdirectories

```yaml
infra_subdirectories:
  cfg:
    path: "{{ infra_directory_path }}/cfg"
  log:
    path: "{{ infra_directory_path }}/log"
  data:
    path: "{{ infra_directory_path }}/data"
```
## Services

### Default restart policy

```yaml
infra_restart_policy: 'always'
```
### Whether to force pull container images

```yaml
infra_force_pull: false
```
### Configure Graylog

```yaml
infra_use_graylog: true
```
### Configure PiHole

```yaml
infra_use_pihole: true
```
### Configure Unifi Controller

```yaml
infra_use_unifi: false
```
### Configure wireguard

```yaml
infra_use_wireguard: false
```
### Configure Vaultwarden

```yaml
infra_use_vaultwarden: true
```
### Configure Authentik

```yaml
infra_use_authentik: true
```
### Configure godns

```yaml
infra_use_godns: false
```
### Configure uptime-kuma

```yaml
infra_use_uptimekuma: true
```
## Unifi

### Directories for Unifi

```yaml
infra_unifi_directories:
  log:
    path: "{{ infra_subdirectories.log.path }}/unifi"
  data:
    path: "{{ infra_subdirectories.data.path }}/unifi"
```
### unifi container hostname

```yaml
infra_unifi_container_hostname: unifi
```
### unifi version

```yaml
infra_unifi_version: latest
```
### unifi container image

```yaml
infra_unifi_container_image: "ghcr.io/linuxserver/unifi-controller:{{ infra_unifi_version }}"
```
### unifi container memory

```yaml
infra_unifi_container_memory: 4g
```
### Middleware for the Unifi container

```yaml
svc_traefik_extra_middlewares:
  unifi-headers-mwr:
    headers:
      customRequestHeaders:
        Authorization: ''
        X-Forwarded-Proto: 'https'
```
### Add a route to the Unifi admin portal (due to network_mode: host on the container)

```yaml
svc_traefik_extra_hosts:
  - name: unifi
    subdomain: "{{ infra_unifi_container_hostname }}"
    shortname: "unifi"
    middlewares: [unifi-headers-mwr, lan-mwr]
    protocol: https
    ip_addr: "{{ ansible_default_ipv4.address }}"
    port: "{{ infra_unifi_container_ports.admin }}"
```
## Pihole

### Directories for Pihole

```yaml
infra_pihole_directories:
  log:
    path: "{{ infra_subdirectories.log.path }}/pihole"
  data:
    path: "{{ infra_subdirectories.data.path }}/pihole"
```
### pihole container hostname

```yaml
infra_pihole_container_hostname: pihole
```
### pihole version

```yaml
infra_pihole_version: latest
```
### pihole container image

```yaml
infra_pihole_container_image: "ghcr.io/pi-hole/pihole:{{ infra_pihole_version }}"
```
### pihole container memory

```yaml
infra_pihole_container_memory: 2g
```
### pihole container ports

```yaml
infra_pihole_container_ports:
  ui: 8053
  dns: 53
```
### Password for Pihole web UI

```yaml
infra_pihole_password: ~
```
### Extra hosts for Pihole

```yaml
infra_pihole_extra_hosts: {}
  # service.domain.tld: <IP_ADDR>
  # service1.domain.tld: <IP_ADDR>
```
### Dnsmasq.d listening setting for pihole

```yaml
infra_pihole_dnsmasq_listening: all
```
## Wireguard

### Directories for Wireguard

```yaml
infra_wireguard_directories:
  log:
    path: "{{ infra_subdirectories.log.path }}/wireguard"
  cfg:
    path: "{{ infra_subdirectories.cfg.path }}/wireguard"
```
### wireguard container hostname

```yaml
infra_wireguard_container_hostname: wg
```
### wireguard version

```yaml
infra_wireguard_version: latest
```
### wireguard container image

```yaml
infra_wireguard_container_image: "ghcr.io/linuxserver/wireguard:{{ infra_wireguard_version }}"
```
### wireguard container memory

```yaml
infra_wireguard_container_memory: 1g
```
```yaml
infra_wireguard_container_ports:
  vpn: 51820
```
### Peers to create. See https://github.com/linuxserver/docker-wireguardparameters

```yaml
infra_wireguard_peers: []
  # - laptop
  # - desktop
  # - phone
```
### Internal subnet for wireguard

```yaml
infra_wireguard_internal_subnet: 10.13.13.0
```
### Internal DNS servers for the wireguard server

```yaml
infra_wireguard_container_dns_servers:
  - "{{ ansible_host }}"
  - 1.1.1.1
  - 1.0.0.1
```
### Settings for the wireguard container. See https://github.com/linuxserver/docker-wireguardparameters

```yaml
infra_wireguard_settings:
  PEERS: "{{ infra_wireguard_peers | join(',') }}"
  PEERDNS: auto
  PERSISTENTKEEPALIVE_PEERS: all
  INTERNAL_SUBNET: "{{ infra_wireguard_internal_subnet }}"
  ALLOWEDIPS: '0.0.0.0/0, ::0/0'
  LOG_CONFS: 'false'
```
## godns

### Directories for godns

```yaml
infra_godns_directories:
  cfg:
    path: "{{ infra_subdirectories.cfg.path }}/godns"
```
### godns container hostname

```yaml
infra_godns_container_hostname: godns
```
### godns version

```yaml
infra_godns_version: latest
```
### godns container image

```yaml
infra_godns_container_image: "ghcr.io/timothyye/godns:{{ infra_godns_version }}"
```
### godns container memory

```yaml
infra_godns_container_memory: 1g
```
### Settings for the godns container. See https://github.com/TimothyYe/godnsconfiguration-properties
DNS provider to use

```yaml
infra_godns_provider: Cloudflare
```
### Email address for the DNS provider account

```yaml
infra_godns_email: ~
```
### Password/Global API key (cloudflare) for the DNS provider account

```yaml
infra_godns_password: ~
```
### Token for the DNS provider account

```yaml
infra_godns_token: ~
```
### List of domains and subdomains to update

```yaml
infra_godns_domains: []
  # - domain_name: "{{ infra_domain_ext }}"
  #   sub_domains:
  #     - "{{ infra_wireguard_container_hostname }}"
```
### Whether to use IPv4 or IPv6 (IPv4|IPv6)

```yaml
infra_godns_ip_type: IPv4
```
### How often (in seconds) the public IP should be updated

```yaml
infra_godns_interval: 300
```
### URLs to use for checking public IPv4 address

```yaml
infra_godns_ip4_urls:
  - https://api.ipify.org
  - https://api.ip.sb/ip
```
### URLs to use for checking public IPv6 address

```yaml
infra_godns_ip6_urls:
  - https://ipify.org
```
### Address of a public DNS server to use

```yaml
infra_godns_resolver: 1.1.1.1
```
### User-Agent header to use when requesting the public IP address

```yaml
infra_godns_user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
```
### SOCKS5 proxy to use

```yaml
infra_godns_socks5_proxy: ~
```
### Whether to use a proxy

```yaml
infra_godns_use_proxy: false
```
### Enable debugging

```yaml
infra_godns_debug_info: false
```
## Vaultwarden

### Directories for Vaultwarden

```yaml
infra_vaultwarden_directories:
  log:
    path: "{{ infra_subdirectories.log.path }}/vaultwarden"
  data:
    path: "{{ infra_subdirectories.data.path }}/vaultwarden"
```
### vaultwarden container hostname

```yaml
infra_vaultwarden_container_hostname: vault
```
### vaultwarden version

```yaml
infra_vaultwarden_version: "1.29.2"
```
### vaultwarden container image

```yaml
infra_vaultwarden_container_image: "ghcr.io/dani-garcia/vaultwarden:{{ infra_vaultwarden_version }}"
```
### vaultwarden container memory

```yaml
infra_vaultwarden_container_memory: 1g
```
### Settings for the vaultwarden container. See https://github.com/dani-garcia/vaultwarden/wiki

```yaml
infra_vaultwarden_settings:
  EXTENDED_LOGGING: 'true'
  LOG_FILE: /data/logs/vaultwarden.log
  LOG_LEVEL: INFO
  SIGNUPS_ALLOWED: 'false'
  SIGNUPS_DOMAINS_WHITELIST: ''
  INVITATIONS_ALLOWED: 'false'
  DISABLE_ADMIN_TOKEN: 'false'
  PASSWORD_ITERATIONS: '350000'
  PASSWORD_HINTS_ALLOWED: 'false'
  SHOW_PASSWORD_HINT: 'false'
```
## Authentik

### Directories for Authentik

```yaml
infra_authentik_directories:
  log:
    path: "{{ infra_subdirectories.log.path }}/authentik"
  data:
    path: "{{ infra_subdirectories.data.path }}/authentik"
```
### authentik container hostname

```yaml
infra_authentik_container_hostname: authentik
```
### authentik version

```yaml
infra_authentik_version: "2023.5.3"
```
### authentik container image

```yaml
infra_authentik_server_container_image: "ghcr.io/goauthentik/server:{{ infra_authentik_version }}"
```
### authentik server container hostname

```yaml
infra_authentik_server_container_hostname: "{{ infra_authentik_container_hostname }}-server"
```
### authentik server container memory

```yaml
infra_authentik_server_container_memory: 2g
```
### authentik worker container hostname

```yaml
infra_authentik_worker_container_hostname: "{{ infra_authentik_container_hostname }}-worker"
```
### authentik worker container memory

```yaml
infra_authentik_worker_container_memory: 2g
```
### authentik redis container hostname

```yaml
infra_authentik_redis_container_hostname: "{{ infra_authentik_container_hostname }}-redis"
```
### authentik redis version

```yaml
infra_authentik_redis_version: alpine
```
### authentik redis container image

```yaml
infra_authentik_redis_container_image: "docker.io/library/redis:{{ infra_authentik_redis_version }}"
```
### authentik redis container memory

```yaml
infra_authentik_redis_container_memory: 1g
```
### authentik redis container hostname

```yaml
infra_authentik_db_container_hostname: "{{ infra_authentik_container_hostname }}-db"
```
### authentik db version

```yaml
infra_authentik_db_version: 12-alpine
```
### authentik postgres container image

```yaml
infra_authentik_db_container_image: "docker.io/library/postgres:{{ infra_authentik_db_version }}"
```
### authentik postgres container memory

```yaml
infra_authentik_db_container_memory: 1g
```
### Secret key used for Authentik cookie signing

```yaml
infra_authentik_secret_key: ""
```
### Database user

```yaml
infra_authentik_db_user: "authentik"
```
### Database password

```yaml
infra_authentik_db_password: ""
```
### Database name

```yaml
infra_authentik_db_name: "authentik"
```
### Settings for the authentik container. See https://goauthentik.io/docs/installation/configurationauthentik-settings

```yaml
infra_authentik_settings:
  AUTHENTIK_COOKIE_DOMAIN: "{{ infra_domain }}"
  AUTHENTIK_LOG_LEVEL: 'INFO'
  AUTHENTIK_GEOIP: /geoip/GeoLite2-City.mmdb
  AUTHENTIK_DISABLE_UPDATE_CHECK: 'false'
  AUTHENTIK_ERROR_REPORTING__ENABLED: 'false'
  AUTHENTIK_ERROR_REPORTING__SENTRY_DSN: ""
  AUTHENTIK_ERROR_REPORTING__ENVIRONMENT: customer
  AUTHENTIK_ERROR_REPORTING__SEND_PII: 'false'
  AUTHENTIK_AVATARS: initials
  AUTHENTIK_DEFAULT_USER_CHANGE_NAME: 'true'
  AUTHENTIK_DEFAULT_USER_CHANGE_EMAIL: 'false'
  AUTHENTIK_DEFAULT_USER_CHANGE_USERNAME: 'false'
  AUTHENTIK_GDPR_COMPLIANCE: 'true'
  AUTHENTIK_DEFAULT_TOKEN_LENGTH: '60'
  AUTHENTIK_IMPERSONATION: 'false'
  AUTHENTIK_EMAIL__HOST: 'localhost'
  AUTHENTIK_EMAIL__PORT: '25'
  AUTHENTIK_EMAIL__USERNAME: ""
  AUTHENTIK_EMAIL__PASSWORD: ""
  AUTHENTIK_EMAIL__USE_TLS: 'false'
  AUTHENTIK_EMAIL__USE_SSL: 'false'
  AUTHENTIK_EMAIL__TIMEOUT: '10'
  AUTHENTIK_EMAIL__FROM: "authentik@{{ infra_domain }}"
```
## Graylog

### Directories for Graylog

```yaml
infra_graylog_directories:
  log:
    path: "{{ infra_subdirectories.log.path }}/graylog"
  data:
    path: "{{ infra_subdirectories.data.path }}/graylog"
```
### graylog container hostname

```yaml
infra_graylog_container_hostname: graylog
```
### graylog version

```yaml
infra_graylog_version: "5.1.7"
```
### Graylog container image

```yaml
infra_graylog_server_container_image: "graylog/graylog:{{ infra_graylog_version }}"
```
### Graylog server container memory

```yaml
infra_graylog_server_container_memory: 4g
```
### graylog mongodb container hostname

```yaml
infra_graylog_db_container_hostname: "{{ infra_graylog_container_hostname }}-db"
```
### graylog mongodb version

```yaml
infra_graylog_db_version: "5.0"
```
### graylog mongodb container image

```yaml
infra_graylog_db_container_image: "mongo:{{ infra_graylog_db_version }}"
```
### graylog mongodb container memory

```yaml
infra_graylog_db_container_memory: 2g
```
### graylog opensearch container hostname

```yaml
infra_graylog_opensearch_container_hostname: "{{ infra_graylog_container_hostname }}-opensearch"
```
### graylog opensearch version

```yaml
infra_graylog_opensearch_version: "2.4.0"
```
### graylog opensearch container image

```yaml
infra_graylog_opensearch_container_image: "opensearchproject/opensearch:{{ infra_graylog_opensearch_version }}"
```
### graylog opensearch container memory

```yaml
infra_graylog_opensearch_container_memory: 6g
```
### Ports for the Graylog server

```yaml
infra_graylog_server_container_ports:
  beats: 5044
  syslog: 5140
  raw: 5555
  http: 9000
  gelf: 12201
  forwarder_data: 13301
  forwarder_cfg: 13302
```
### Log driver for the graylog containers

```yaml
infra_graylog_log_driver: local
```
```yaml
infra_graylog_log_options:
  max-size: 20m
  max-file: '5'
  compress: 'true'
```
### Secret used to 'pepper' the passwords - make sure to change this BEFORE deploying.

```yaml
infra_graylog_password_secret: "vSQBO0P8JLC//sWG0V1JkvRycKkDXZ6WQN4eOrrALy/JYc8nWsvxMSg29Eel1fscVUfbmpxlNmJEzYf6I3pcK1iXXpdzAhoSiV18I89N7+0QzpcI1ygANBwmRYWLd4Hp"
```
### Hash of the password used for the root user [run `echo -n yourpassword | shasum -a 256`]

```yaml
infra_graylog_password_sha2: "f5dcec9289c446e7099d483f2ed447c990b3868a2fab4ff4a39436c63589c70e"
```
### Settings for the Graylog config. See https://github.com/Graylog2/graylog-dockerconfiguration

```yaml
infra_graylog_settings: {}
```
## Uptime-Kuma

### Directories for uptime-kuma

```yaml
infra_uptimekuma_directories:
  log:
    path: "{{ infra_subdirectories.log.path }}/uptimekuma"
  data:
    path: "{{ infra_subdirectories.cfg.path }}/uptimekuma"
```
### uptimekuma container hostname

```yaml
infra_uptimekuma_container_hostname: uptime
```
### uptimekuma version

```yaml
infra_uptimekuma_version: "1.23.1-alpine"
```
### uptimekuma container image

```yaml
infra_uptimekuma_container_image: "louislam/uptime-kuma:{{ infra_uptimekuma_version }}"
```
### uptimekuma container memory

```yaml
infra_uptimekuma_container_memory: 1g
```
### uptimekuma extra settings (env vars). See https://github.com/louislam/uptime-kuma/wiki/Environment-Variables

```yaml
infra_uptimekuma_settings: {}
```