---
title: 'Configure NetApp ONTAP NFS with Proxmox VE'
date: 2025-10-04
---

## Multipathing with NFS
To achieve multipathing with ONTAP NFS and Proxmox you should use NFS Session Trunking. Trunking opens multiple connections to differents LIF's (IP's) on the NetApp NFS Server, increasing throuput and resiliency

Read more on ONTAP NFS trunking at https://docs.netapp.com/us-en/ontap/nfs-trunking/

On yout NFS server you need to enable NFS trunking with the below command, in this case we create an NFS server with the option **-v4.2 enabled -v4.2-trunking enabled**

```
vserver nfs create -vserver svm_name -v3 disabled -v4.0 disabled -v4.2 enabled -v4.2-trunking enabled -v4-id-domain my_domain.com
```

```bash
#storage.cfg

nfs: netapp_nfs_vol1
      export /netapp_nfs_vol1
      path /mnt/pve/netapp_nfs_vol1
      server 10.0.0.10
      content iso,vztmpl,images,import,backup,snippets,rootdir
      options max_connect=16,nconnect=16,hard,trunkdiscovery,vers=4.2
```

The important part in the nfs configuration above is the NFS options, let's break them down.

### vers=4.2

This option is kind of obvious but it forces the NFS version to 4.2 - in my configuration with PVE and ONTAP it works great. You could also use version 4.1 that also support more advanced features than NFS v3.

### hard

This option enables the mount to wait indefinitely if the NFS server becomes unreachable. This is a good option for VM images to avoid data corruption. The VMs may appear "hung" while the NFS server is unavailable. 

This is usually recommended for production environments.

### nconnect=16

The feature nconnect enables parallel TCP connections to the NFS server to improve througput and reduce contention. This is particurally useful on high perfromance netwrosk like 10/25/10/100GbE. This feature greatly increase performance for concurrent I/O.

### trunkdiscovery

In NFSv4.1 & 4.2 this option enables session trunking discovery. If there's multiple IPs that belong to the same NFS server the mount uses them and spreads connections across the multiple IPs. This is very useful for load-balancing and resilience as you are not dependent on one IP for the mount.

This requires that you enable trunk discovery on the ONTAP side as well.

### max_connect=16

This option limits the total number of TCP connections the Proxmox client will establish to the storage NFS server for the mount. This is useful in combination with nconnect & trunkdiscovery. 

Example: If trunkdiscovery finds 2 server IPs and nconnect=16, the client might otherwise create 32 connections (16 per IP). max_connect=16 keeps the total at 16 across all paths.


