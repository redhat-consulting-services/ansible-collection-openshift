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

| Type | Hostname                 | IP Address      |
|------|--------------------------|-----------------|
| NTP  | ntp1.example.com         | 192.168.255.100 |
| NTP  | ntp2.example.com         | 192.168.255.101 |
| DNS  | ns1.example.com          | 192.168.254.11  |
| DNS  | ns2.example.com          | 192.168.254.12  |

| Type         | CIDR              | Gateway        |
|--------------|-------------------|----------------|
| Host network | 10.10.10.0/24     | 10.10.10.1     |
| Pod network  | 10.172.0.0/14     | N/A            |
| Service net  | 10.171.0.0/16     | N/A            |

| Type | Value                          |
|------|--------------------------------|
| MTU  | 1500                           |
| VLAN | 1111                           |
| Bond | bond0 (mode=802.3ad)           |
| Server Hardware | Dell PowerEdge R640 |

| Role          | Hostname                   | BMC IP Address | IP Address     | NIC Details                                   | Disk Details                            |
|---------------|----------------------------|----------------|----------------|-----------------------------------------------|-----------------------------------------|
| master        | master-01.ocp1.example.com | 10.10.9.10     | 10.10.10.10    | eth0=00:01:00:00:00:01 eth1=00:01:00:00:00:02 | sda=240G serial_number=0000000000000001 |
| master        | master-02.ocp1.example.com | 10.10.9.11     | 10.10.10.11    | eth0=00:01:00:00:01:01 eth1=00:01:00:00:01:02 | sda=240G serial_number=0000000000000002 |
| master        | master-03.ocp1.example.com | 10.10.9.12     | 10.10.10.12    | eth0=00:01:00:00:02:01 eth1=00:01:00:00:02:02 | sda=240G serial_number=0000000000000003 |
| worker        | worker-01.ocp1.example.com | 10.10.9.20     | 10.10.10.20    | eth0=00:02:00:00:00:01 eth1=00:02:00:00:00:02 | sda=240G serial_number=0000010000000001 |
| worker        | worker-02.ocp1.example.com | 10.10.9.21     | 10.10.10.21    | eth0=00:02:00:00:01:01 eth1=00:02:00:00:01:02 | sda=240G serial_number=0000010000000002 |
| worker        | worker-03.ocp1.example.com | 10.10.9.22     | 10.10.10.22    | eth0=00:02:00:00:02:01 eth1=00:02:00:00:02:02 | sda=240G serial_number=0000010000000003 |
| worker        | worker-04.ocp1.example.com | 10.10.9.23     | 10.10.10.23    | eth0=00:02:00:00:03:01 eth1=00:02:00:00:03:02 | sda=240G serial_number=0000010000000004 |
| worker        | worker-05.ocp1.example.com | 10.10.9.24     | 10.10.10.24    | eth0=00:02:00:00:04:01 eth1=00:02:00:00:04:02 | sda=240G serial_number=0000010000000005 |
| worker        | worker-06.ocp1.example.com | 10.10.9.25     | 10.10.10.25    | eth0=00:02:00:00:05:01 eth1=00:02:00:00:05:02 | sda=240G serial_number=0000010000000006 |
| worker        | worker-07.ocp1.example.com | 10.10.9.26     | 10.10.10.26    | eth0=00:02:00:00:06:01 eth1=00:02:00:00:06:02 | sda=240G serial_number=0000010000000007 |
| worker        | worker-08.ocp1.example.com | 10.10.9.27     | 10.10.10.27    | eth0=00:02:00:00:07:01 eth1=00:02:00:00:07:02 | sda=240G serial_number=0000010000000008 |
| worker        | worker-09.ocp1.example.com | 10.10.9.28     | 10.10.10.28    | eth0=00:02:00:00:08:01 eth1=00:02:00:00:08:02 | sda=240G serial_number=0000010000000009 |

## Execute the Playbook

To run the playbook using ansible-navigator, use the following command:

```bash
ansible-navigator run playbook.yml -i inventory/hosts.yaml
```
