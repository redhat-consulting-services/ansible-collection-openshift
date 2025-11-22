# ansible-role-cluster-bootstrap

An Ansible role for booting an OpenShift cluster. This role uses the agent-based installation method.

## Role Variables

```yaml
# tenant_name is an optional variable that can be used to specify the tenant name for the cluster (metadata.namespace).
tenant_name: "my-tenant"
# cluster_name is a variable that specifies the name of the cluster. The cluster_name together with the base_domain determines the cluster's API and ingress domain names.
# It is required to be set.
cluster_name: "my-cluster"

# type defines the installation type of the OpenShift cluster.
# Available types: baremetal, none
# none should be used for single instance OpenShift clusters that are not installed on bare metal.
# baremetal should be used for OpenShift clusters that are installed on bare metal (default).
type: baremetal

# boot_artifacts_base_url is optional, if not provided, it will not be included in the agent-config.yaml
# boot_artifacts_base_url: "http://example.com/boot-artifacts"

# additional_ntp_sources is optional, if not provided, it will not be included in the agent-config.yaml
# additional_ntp_sources:
#   - "0.pool.ntp.org"
#   - "1.pool.ntp.org"

# base_domain is the base domain for the cluster. It is required to be set.
# It is used to generate the cluster's API and ingress domain names.
base_domain: "example.com"

# pull_secret is the pull secret for the cluster. It is required to be set.
# It is used to authenticate with the OpenShift container registry and other registries.
# The pull secret is a JSON string that contains the authentication information for the registries.
pull_secret: |
    {"auths":{"cloud.openshift.com":{"auth":"dXNlcm5hbWU6cGFzc3dvcmQK","email":"user@example.com"},"quay.io":{"auth":"dXNlcm5hbWU6cGFzc3dvcmQK","email":"user@example.com"},"registry.connect.redhat.com":{"auth":"dXNlcm5hbWU6cGFzc3dvcmQK","email":"user@example.com"},"registry.redhat.io":{"auth":"dXNlcm5hbWU6cGFzc3dvcmQK","email":"user@example.com"}}}

# additional_trust_bundle is an optional variable that can be used to specify additional trust bundle certificates.
# Ensure that the registry certificates are included in the additional_trust_bundle.
additional_trust_bundle: |
    -----BEGIN CERTIFICATE-----
    MIID...
    -----END CERTIFICATE-----

# image_digest_sources is a list of sources for the OpenShift release images.
# This key is opitional and must only be set if the OpenShift cluster runs on a disconnected environment.
# If not set, the OpenShift release images will be pulled from the default source registry (quay.io/openshift-release-dev/ocp-release and quay.io/openshift-release-dev/ocp-v4.0-art-dev).
image_digest_sources:
  -
    # source is the source registry for the OpenShift release image. This is usully quay.io
    source: "quay.io/openshift-release-dev/ocp-release"
    # mirrors is a list of mirrors the OpenShift release images should be pushed to.
    mirrors:
      - "registry.example.com/mirror/ocp4/openshift-release"

# ssh_public_key is the SSH public key that will be used to access the cluster nodes.
# It is optional, if not provided, it will not be included in the agent-config.yaml (thereforce, the nodes will not be accessible via SSH).
ssh_public_key: |
    ssh-ed25519 AAAAA... user@machine

# rendezvous_ip is the IP address of the rendezvous server. It is used to connect all the nodes in the cluster (usually first master node).
# The rendezvous server is used to coordinate the cluster installation and configuration.
# If not provided, the first masters IP address will be used as the rendezvous server.
rendezvous_ip: 172.16.11.20

# api_vip is the virtual IP address pointing to the cluster's API load balancer.
api_vip: ""

# ingress_vip is the virtual IP address pointing to the cluster's ingress load balancer.
# It is used to access the cluster's ingress. Therefore, it is required to be set
ingress_vip: ""

# enable_fips is a boolean variable that specifies whether FIPS mode should be enabled for the cluster.
# https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/installing/installing-on-bare-metal#installation-configuration-parameters-optional_installing-bare-metal --> fips
enable_fips: false

# networking defines the cluster's networking configuration.
# It is required to be set.
networking:
  # cluster_networks defines the nodes' cluster networks.
  # Each node receives a unique IP address range from the cluster_networks to be used for pod networking.
  # The CIDR and host_prefix are required to be set.
  cluster_networks:
    -
      # cidr defines the pod network CIDR. Each node receives a unique IP address range from the cluster_networks to be used for pod networking. Ensure that the CIDR is large enough to accommodate the number of nodes in the cluster.
      cidr: "10.128.0.0/14"
      # host_prefix defines the size of the IP address range for each node in the cluster_networks. It is used to calculate the number of IP addresses available for each node.
      host_prefix: 23
  # service_networks defines the cluster internal service networks. Each network must be a unique CIDR and should not overlap with the cluster_networks.
  # The CIDR is required to be set.
  service_networks:
    - 172.30.0.0/16
  # machine_network defines the machine network CIDR. It is used to configure the machine network for the cluster. Ensure that the CIDR is large enough to accommodate the number of nodes in the cluster.
  machine_network:
    -
      # cidr defines the machine network CIDR.
      cidr: 192.168.255.0/24

  # network_type defines the type of networking to be used in the cluster. It is required to be set.
  network_type: "OVNKubernetes"

# generate_iso is a boolean variable that specifies whether an ISO file should be generated for the OpenShift installation.
# If set to true, the role will generate an ISO file with the OpenShift installation configs.
# The ISO file will be stored in the `iso_output_dir` directory.
generate_iso: false

# iso_type determines whether an ISO file or PXE bootable artifacts should be generated.
# Valid values are "iso" or "pxe".
# Default is "iso".
iso_type: "iso"

# iso_output_dir is the directory where the OpenShift installation configs and ISO files will be stored.
# It is required to be set.
iso_output_dir: "/opt/openshift/iso"

# proxy allows to configure the http, https and no_proxy settings for the OpenShift cluster.
proxy:
  # http is the HTTP proxy URL to be used by the OpenShift cluster.
  # It is optional, if not provided, it will not be included in the install-config.yaml
  http: ""
  # https is the HTTPS proxy URL to be used by the OpenShift cluster.
  # It is optional, if not provided, it will not be included in the install-config.yaml
  https: ""
  # no_proxy is a comma-separated list of hosts that should not use the proxy.
  # It is optional, if not provided, it will not be included in the install-config.yaml
  no_proxy: ""

# agent_config defines the configuration for the OpenShift cluster's agent-based installation.
# It contains the configuration for the master and worker nodes.
agent_config:
  # master|worker defines the configuration for either the master or worker nodes. In both cases, the configuration is the same.
  <master|worker>:
    # hostname_prefix is the prefix for the hostnames of the nodes. It is used to generate the hostnames using the prefix and the node id.
    # If the hosts[].hostname variable is set, this prefix is ignored and the hostname is used instead.
    # Example: If the hostname_prefix is `master-` and the node id is `0`, the generated hostname is `master-0`.
    hostname_prefix: "master-"
    # root_device_name is the name of the root device for the nodes.
    # This option only applies if `hosts[].root_device.name`, `hosts[].root_device.serial_number`, `hosts[].root_device.wwn` are not set.
    root_device_name: "/dev/sda"
    # bonds defines the bonding configuration for the nodes.
    bonds:
      -
        # name is the name of the bond interface.
        name: bond0
        # mode defines the bonding mode.
        # Available modes: balance-rr, active-backup, balance-xor, broadcast, 802.3ad, balance-tlb, balance-alb
        mode: "balance-rr"
        # options defines the bonding options. Any options can be set here as a key-value pair.
        options:
          miimon: "100"
          lacp_rate: "fast"
    # bridges defines the bridge configuration for the nodes.
    bridges:
      -
        # name is the name of the bridge interface.
        name: br0
        # type is the type of the bridge interface.
        # Available types: ovs-bridge, linux-bridge
        type: ovs-bridge
        # interfaces defines the interfaces that are part of the bridge.
        interfaces:
          -
            # name is the name of the interface that is part of the bridge.
            name: bond0
    # vlans defines the VLAN configuration for the nodes.
    vlans:
      -
        # name is the name of the VLAN interface.
        name: bond0.100
        # id is the VLAN ID.
        id: 100
        # base_interface is the reference to the interface that the VLAN interface is based on.
        base_interface: bond0
    # hosts defines all the hosts part of the node group (master / worker).
    hosts:
      # master / worker: 0
      -
        # hostname (optional) explicitly defines the hostname of the host. If this is set, hostname_prefix is ignored.
        hostname: "master-0"
        # root_device defines the root device RHCOS will be installed on.
        root_device:
          # name (optional) is the name of the root device. It is recommended to use the `/dev/disk/by-path/<device_path>` path.
          name: "/dev/sda"
          # serial_number (optional) is the serial number of the root device.
          serial_number: "1234567890"
          # wwn (optional) is the World Wide Name (WWN) of the root device.
          wwn: "1234567890abcdef"
        # interfaces defines a list of interfaces of the host. This list is also used to identify the host and assign the correct OpenShift cluster boot artifacts.
        interfaces:
          -
            # name is the name of the interface.
            name: enp0s0
            # mac_address is the MAC address of the interface. It is used to identify the interface for the host.
            mac_address: "00:00:00:00:00:00"
            # part_of_bond is the name of the bond interface that the interface is part of. This setting must match the bond name defined in `bonds[].name`.
            part_of_bond: "bond0"
            # mtu (optional) is the MTU of the interface. If not set, the default MTU of the hardware will be used.
            mtu: 1500
        # bonds defines the host specific bond configuration.
        bonds:
          -
            # interface is the name of the bond interface to which an IP address should be assigned.
            # This interface must match the name of the bond interface defined in `bonds[].name`.
            interface: bond0
            # addresses defines the IP addresses for the interface.
            addresses:
              -
                # ip is the IPv4 or IPv6 address to assign to the interface.
                ip: 192.168.10.222
                # subnet_length is the subnet length for the interface.
                subnet_length: 24
        # vlans defines the host specific bond configuration.
        vlans:
          -
            # interface is the name of the bond interface to which an IP address should be assigned.
            # This interface must match the name of the bond interface defined in `vlans[].name`.
            interface: bond0.100
            # addresses defines the IP addresses for the interface.
            addresses:
              -
                # ip is the IPv4 or IPv6 address to assign to the interface.
                ip: 192.168.10.222
                # subnet_length is the subnet length for the interface.
                subnet_length: 24
```

## Role facts

When this role is executed, it will set the following facts automatically:

| Fact Name               | Description                                      |
|-------------------------|--------------------------------------------------|
| base_dir                | The generated base directory in which the ISO and installation configs are stored. |
| manifest_folder         | The generated directory where the agent-config.yaml and install-config.yaml files are backed up. |
| kubeconfig_path         | The generated path to the kubeconfig file. |
| kubeadmin_password_path | The generated path to the kubeadmin password file. |
| bootfile_path           | The generated path to the bootable ISO file or PXE artifacts. |

## Example Playbook

```yaml
- name: Bootstrap OpenShift Cluster
  hosts: localhost
  gather_facts: false
  become: false
  vars_files:
    - ./cluster_config.yaml
  roles:
    - redhat_consulting_services.openshift.bootstrap_cluster
```

For a more detailed example, please refer to the `examples/cluster-setup/playbook.yaml` file in this collection.
