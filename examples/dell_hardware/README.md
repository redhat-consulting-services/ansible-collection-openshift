# cluster-setup

In this example, we demonstrate how to set up an OpenShift cluster using the provided Ansible collection. The setup includes bootstrapping the cluster and adding nodes. As part of this example, we utilize an Ansible Execution Environment (EE) that contains all necessary dependencies and OpenShift CLI tools.

## Prerequisites

- ansible core 2.18.x or higher (older versions might work but are not tested)
- ansible-navigator 24.2.0 or higher (older versions might work but are not tested)
- Docker or Podman installed to run the Ansible Execution Environment
- Access to a private container registry (if mirroring images)
- Properly configured inventory and cluster configuration files

## Example setup

As part of this example, we assume the following server and network setup:

| Type               | Hostname                 | IP Address      |
|--------------------|--------------------------|-----------------|
| NTP                | ntp1.example.com         | 192.168.255.100 |
| NTP                | ntp2.example.com         | 192.168.255.101 |
| DNS                | ns1.example.com          | 192.168.254.11  |
| DNS                | ns2.example.com          | 192.168.254.12  |
| Container Registry | registry.example.com     | 192.168.254.200 |

| Type         | CIDR              | Gateway        |
|--------------|-------------------|----------------|
| Host network | 10.10.10.0/24     | 10.10.10.1     |
| Pod network  | 10.172.0.0/14     | N/A            |
| Service net  | 10.171.0.0/16     | N/A            |

| Type            | Value                          |
|-----------------|--------------------------------|
| MTU             | 1500                           |
| VLAN            | 1111                           |
| Bond            | bond0 (mode=802.3ad)           |
| Server Hardware | Dell PowerEdge R640            |

| Role          | Hostname                   | BMC IP Address | IP Address     | NIC Details                                   | Disk Details                            |
|---------------|----------------------------|----------------|----------------|-----------------------------------------------|-----------------------------------------|
| master        | master-01.ocp.example.com | 10.10.9.10     | 10.10.10.10    | eth0=00:01:00:00:00:01 eth1=00:01:00:00:00:02 | sda=240G serial_number=0000000000000001 |
| master        | master-02.ocp.example.com | 10.10.9.11     | 10.10.10.11    | eth0=00:01:00:00:01:01 eth1=00:01:00:00:01:02 | sda=240G serial_number=0000000000000002 |
| master        | master-03.ocp.example.com | 10.10.9.12     | 10.10.10.12    | eth0=00:01:00:00:02:01 eth1=00:01:00:00:02:02 | sda=240G serial_number=0000000000000003 |
| infra         | infra-01.ocp.example.com  | 10.10.9.20     | 10.10.10.20    | eth0=00:02:00:00:00:01 eth1=00:02:00:00:00:02 | sda=240G serial_number=0000010000000001 |
| infra         | infra-02.ocp.example.com  | 10.10.9.21     | 10.10.10.21    | eth0=00:02:00:00:01:01 eth1=00:02:00:00:01:02 | sda=240G serial_number=0000010000000002 |
| infra         | infra-03.ocp.example.com  | 10.10.9.22     | 10.10.10.22    | eth0=00:02:00:00:02:01 eth1=00:02:00:00:02:02 | sda=240G serial_number=0000010000000003 |
| worker        | worker-01.ocp.example.com | 10.10.9.31     | 10.10.10.31    | eth0=00:03:00:00:01:01 eth1=00:03:00:00:01:02 | sda=240G serial_number=0000020000000001 |
| worker        | worker-02.ocp.example.com | 10.10.9.32     | 10.10.10.32    | eth0=00:03:00:00:02:01 eth1=00:03:00:00:02:02 | sda=240G serial_number=0000020000000002 |
| worker        | worker-03.ocp.example.com | 10.10.9.33     | 10.10.10.33    | eth0=00:03:00:00:03:01 eth1=00:03:00:00:03:02 | sda=240G serial_number=0000020000000003 |
| worker        | worker-04.ocp.example.com | 10.10.9.34     | 10.10.10.34    | eth0=00:03:00:00:04:01 eth1=00:03:00:00:04:02 | sda=240G serial_number=0000020000000004 |
| worker        | worker-05.ocp.example.com | 10.10.9.35     | 10.10.10.35    | eth0=00:03:00:00:05:01 eth1=00:03:00:00:05:02 | sda=240G serial_number=0000020000000005 |
| worker        | worker-06.ocp.example.com | 10.10.9.36     | 10.10.10.36    | eth0=00:03:00:00:06:01 eth1=00:03:00:00:06:02 | sda=240G serial_number=0000020000000006 |

## Execute the Playbooks

### Cluster installation

As part of the installation playbook, we perform the following tasks:

- Generate the OpenShift ISO with the specified configuration
- Copy the ISO to the appropriate NFS share
- Configure the Dell hardware using the BMC (iDRAC) to boot from the ISO
- Monitor the installation process until completion
- Configure initial OLM (Operator Lifecycle Manager) settings to set up OpenShift GitOps
- Install the OpenShift GitOps operator

```bash
ansible-navigator run playbook-install.yml -i inventory/hosts.yaml
```

### Scale nodes

To scale the cluster by adding additional nodes, we use the scaling playbook. This playbook performs the following tasks:

- Generate a new OpenShift ISO for the additional nodes
- Copy the ISO to the NFS share
- Configure the Dell hardware to boot from the new ISO
- Monitor the installation process until completion

```bash
ansible-navigator run playbook-scaling.yaml -i inventory/hosts.yaml
```
