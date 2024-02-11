---
title: Core Services needed to run VMware vSphere
date: "2019-08-04"
description: "What do you need in place before you set up VMware vSphere? In this post, you'll learn about the core services DNS, NTP, CA, and AD."
---
Often when we set up vSphere environments, there are already some things running. Sometimes it may be an Active Directory domain with DNS, NTP, CA, and all that setup. However, if you're setting up a completely new environment, none of that may exist. What should you do then? We'll cover all of that in this post.

People often discard the importance of core services. For example, they install vSphere with static entries in the host file instead of using a DNS server. It may work, but it's hell to operate and maintain. When shit hits the fan, and eventually it does, it helps to have followed the best practices described in this post.

In this post, we'll cover all of the needed core services for vSphere to function correctly.

# Design
You do need to put some effort into the overall design of the environment you're planning to deploy. It involves what core services you need as well as the redundancy and the separation of core services versus production workloads. It's best practice to have these two separate, but not all companies invest in both a production cluster and a management cluster. Usually, it depends on the size of the deployment. 

When you have a large amount of hardware, it's more motivated to invest in a dedicated management cluster. However, if it's a small deployment, it's a significant investment for the company to buy hardware for the management part. The problem comes when everything goes down. What happens then? vSphere needs DNS to function but what if the DNS servers are down? It's a chicken and egg situation. To mitigate issues you need to use anti-affinity described later in this post. If you have the core services running in a separate cluster, it's a lot easier.

## The primary core services we cover are:
### DNS - Domain Name Service

We need at least two DNS servers to achieve redundancy. These usually are part of the Active Directory domain which we are going to cover later on in this post. You typically install a minimum of two domain controllers and both usually have the DNS service installed.

It's recommended to always configure static IP-addresses on each service ensuring it retains IP after a reboot. When I say services in this sentence, I mean vCenter, ESXi, and other VMware products.

[VMware - vSphere DNS requirements.](https://docs.vmware.com/en/VMware-vSphere/6.0/com.vmware.vsphere.upgrade.doc/GUID-1DD8E69C-4551-4C18-8698-7BFE01BEA8B7.html)

The requirements cover two things that are important to configure, and it's to have both forward and reverse lookup zones.
* **Forward Lookup**

    Translates names to IP.
* **Reverse Lookup**

    The reverse of forwarding zones. The ability to query the DNS server for the FQDN of a specific IP-address.

### NTP - Network Time Protocol

Network Time Protocol is a protocol to where the client syncs the time with a server. It's essential to have the correct time-synchronized throughout the environment. When there's a mismatch in time on ESXi hosts, the VM's could get the wrong time if they sync with the system clock. I've experienced this several times, and it's a pain! Also, when you troubleshoot, there's helpful to have the same time across different services and logs. There could also be regulatory compliance within the environment, a payment system, for example.

Best practices from VMware is to have an authoritative NTP server as a time source, for example, your domain controllers. You also need to have these NTP servers configured to use a reliable source such as an on-premise GPS or one of the trusted external NTP pools. I use se.pool.ntp.org because I live in Sweden :)

[Interesting blog post from VMware about time in ESXi.](https://blogs.vmware.com/vsphere/2018/07/timekeeping-within-esxi.html)
 
### CA - Certificate Authority

Certificate Authority is a server that issues certificates. The purpose of digital certificates is to maintain a chain of trust and to provide encryption. The certificate contains information about both these things. You know when you browse to a newly installed ESXi host you get certificates errors and manually needs to approve to continue? That's when you've got the encryption, but your computer doesn't trust the certificate chain! That's because ESXi creates the certificates and you've never come across them before. 

The new vCenter appliance contains a certificate mode called *"Hybrid Mode"* and that when you let the VMware Certificate Authority to be a subordinate certificate authority. That means that you only need to configure hybrid mode on the vCenter appliance and distribute the root certificate to your clients. The subordinate CA takes care of the rest; it signs new certificates to the ESXi hosts and other services inside vCenter. 

[VMware Docs - Use VMCA as an Intermediate Certificate Authority.](https://docs.vmware.com/en/VMware-vSphere/6.0/com.vmware.vsphere.security.doc/GUID-5FE583A2-3737-4B62-A905-5BB38D479AE0.html)
 
### Authentication - Active Directory

Active Directory is(among other things) a service providing identity services. Identity service is the last requirement that we haven't covered yet. Identity service and authentication are required to implement role-based access(RBAC), which is a way to grant different users different permissions. One example would be that you have a service desk group where users only should be able to use VM actions such as reboot, power on, off, and so on. It is possible with Active Directory combined with vSphere. It's also possible with integrated users and other identity services, but Active Directory is the most commonly used.

[VMware Docs - Join or Leave an Active Directory Domain.](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.vcsa.doc/GUID-08EA2F92-78A7-4EFF-880E-2B63ACC962F3.html)

## Conclusion

If we summarize the post, we see that AD could help us maintain all of the requirements for a new environment: authentication, DNS, NTP, and CA.

The minimum requirement would be two domain controllers, bot with AD, DNS & NTP but only one with CA. The CA is just a passive service that signs certificates, so it doesn't need to be online all the time.

You would ideally put these two VM's either in a management cluster or in the production cluster, but in either case, you would use anti-affinity rules. Anti-affinity rules keep virtual machines on different hosts all the time. [Read more about that here.](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.resmgmt.doc/GUID-FBE46165-065C-48C2-B775-7ADA87FF9A20.html)

In the best of worlds, I argue that a physical domain controller to be used alongside the virtual one. It's one of the most critical servers that is running in your environment, and when you run it physically, you remove a bit of overhead. I'm not saying that there's anything wrong running virtual machines, but a physical machine doesn't have that extra layer of virtualization. 

Here are some topics covering Active Directory in a virtualized environment.
[Microsoft Docs - Virtualize Active Directory](https://support.microsoft.com/en-us/help/888794/things-to-consider-when-you-host-active-directory-domain-controllers-i)

[VMworld US 2018 - Virtualize your Active Directory the Right Way! (VAP1898BU)](https://www.youtube.com/watch?v=T5kKNBsJEJc)