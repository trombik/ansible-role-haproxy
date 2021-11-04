# `trombik.haproxy`

`ansible` role for `haproxy`.

The role supports TLS by including
[`trombik.x509_certificate`](https://github.com/trombik/ansible-role-x509_certificate).
See [tests/serverspec/tls.yml](tests/serverspec/tls.yml) for an example.

## For CentOS users

The role permanently enables SELinux security policy
`httpd_can_network_connect` to `1`.

# Requirements

The role requires the following `ansible` collections.

* `community.general`
* `ansible.posix`

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `haproxy_user` | User name of `haproxy` | `{{ __haproxy_user }}` |
| `haproxy_group` | Group name of `haproxy` | `{{ __haproxy_group }}` |
| `haproxy_service` | Service name of `haproxy` | `{{ __haproxy_service }}` |
| `haproxy_package` | Name of `haproxy` package | `{{ __haproxy_package }}` |
| `haproxy_extra_packages` | A list of extra packages to install | `[]` |
| `haproxy_conf_dir` | Path to configuration directory | `{{ __haproxy_conf_dir }}` |
| `haproxy_conf_file` | Path to `haproxy` configuration file | `{{ __haproxy_conf_dir }}/haproxy.cfg` |
| `haproxy_config` | Content of `haproxy_conf_file` | `""` |
| `haproxy_flags` | TBW | `""` |
| `haproxy_chroot_dir` | Path to directory for `haproxy` `chroot(8)` to | `{{ __haproxy_chroot_dir }}` |
| `haproxy_selinux_seport` | See below | `{}` |
| `haproxy_x509_certificate_enable` | If yes, include [`trombik.x509_cetificte`](https://github.com/trombik/ansible-role-x509_certificate) role during the play. | `no` |
| `haproxy_x509_certificate` | List of certificates for `trombik.x509_certificate` | `[]` |
| `haproxy_x509_certificate_debug_log` | Enable debug log when playing `trombik.x509_certificate` role | `no` |

## `haproxy_selinux_seport`

This variable is a dict for RedHat only. The variable is passed to
[`community.general.seport`](https://docs.ansible.com/ansible/latest/collections/community/general/seport_module.html).
It accepts all parameters that `community.general.seport` accepts.

## Debian

| Variable | Default |
|----------|---------|
| `__haproxy_user` | `haproxy` |
| `__haproxy_group` | `haproxy` |
| `__haproxy_service` | `haproxy` |
| `__haproxy_conf_dir` | `/etc/haproxy` |
| `__haproxy_package` | `haproxy` |
| `__haproxy_log_dir` | `/var/log/haproxy` |
| `__haproxy_chroot_dir` | `/var/lib/haproxy` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__haproxy_user` | `www` |
| `__haproxy_group` | `www` |
| `__haproxy_service` | `haproxy` |
| `__haproxy_conf_dir` | `/usr/local/etc` |
| `__haproxy_package` | `haproxy` |
| `__haproxy_log_dir` | `/var/log/haproxy` |
| `__haproxy_chroot_dir` | `/var/haproxy` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__haproxy_user` | `_haproxy` |
| `__haproxy_group` | `_haproxy` |
| `__haproxy_service` | `haproxy` |
| `__haproxy_conf_dir` | `/etc/haproxy` |
| `__haproxy_package` | `haproxy` |
| `__haproxy_chroot_dir` | `/var/haproxy` |

## RedHat

| Variable | Default |
|----------|---------|
| `__haproxy_user` | `haproxy` |
| `__haproxy_group` | `haproxy` |
| `__haproxy_service` | `haproxy` |
| `__haproxy_conf_dir` | `/etc/haproxy` |
| `__haproxy_package` | `haproxy` |
| `__haproxy_log_dir` | `/var/log/haproxy` |
| `__haproxy_chroot_dir` | `/var/lib/haproxy` |

# Dependencies

[`trombik.x509_certificate`](https://github.com/trombik/ansible-role-x509_certificate)
when `haproxy_x509_certificate_enable` is `yes`.

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - ansible-role-haproxy
  vars:
    project_backend_host: 127.0.0.1
    project_backend_port: 8000
    os_haproxy_selinux_seport:
      FreeBSD: {}
      Debian: {}
      RedHat:
        ports:
          - 80
          - 8404
        proto: tcp
        setype: http_port_t
    haproxy_selinux_seport: "{{ os_haproxy_selinux_seport[ansible_os_family] }}"
    haproxy_config: |
      global
        daemon
      {% if ansible_os_family == 'FreeBSD' %}
      # FreeBSD package does not provide default
        maxconn 4096
        log /var/run/log local0 notice
          user {{ haproxy_user }}
          group {{ haproxy_group }}
      {% elif ansible_os_family == 'Debian' %}
        log /dev/log  local0
        log /dev/log  local1 notice
        chroot {{ haproxy_chroot_dir }}
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user {{ haproxy_user }}
        group {{ haproxy_group }}

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
          ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
          ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
      {% elif ansible_os_family == 'OpenBSD' %}
        log 127.0.0.1   local0 debug
        maxconn 1024
        chroot {{ haproxy_chroot_dir }}
        uid 604
        gid 604
        pidfile /var/run/haproxy.pid
      {% elif ansible_os_family == 'RedHat' %}
      log         127.0.0.1 local2
      chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
      maxconn     4000
      user        haproxy
      group       haproxy
      daemon
      {% endif %}

      defaults
        log global
        mode http
        timeout connect 5s
        timeout client 10s
        timeout server 10s
        option  httplog
        option  dontlognull
        retries 3
        maxconn 2000
      {% if ansible_os_family == 'Debian' %}
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http
      {% elif ansible_os_family == 'OpenBSD' %}
        option  redispatch
      {% endif %}

      frontend http-in
        bind *:80
        default_backend servers

      backend servers
        option forwardfor
        server server1 {{ project_backend_host }}:{{ project_backend_port }} maxconn 32 check

      frontend stats
        bind *:8404
        mode http
        no log
        acl network_allowed src 127.0.0.0/8
        tcp-request connection reject if !network_allowed
        stats enable
        stats uri /
        stats refresh 10s
        stats admin if LOCALHOST

    os_haproxy_flags:
      FreeBSD: |
        haproxy_config="{{ haproxy_conf_file }}"
        #haproxy_flags="-q -f ${haproxy_config} -p ${pidfile}"
      Debian: |
        #CONFIG="/etc/haproxy/haproxy.cfg"
        #EXTRAOPTS="-de -m 16"
      OpenBSD: ""
      RedHat: |
        OPTIONS=""
    haproxy_flags: "{{ os_haproxy_flags[ansible_os_family] }}"
    haproxy_extra_packages:
      - zsh
```

# License

```
Copyright (c) 2021 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
