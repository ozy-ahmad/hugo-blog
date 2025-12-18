
---
title: "Moving my personal website to Hugo"
date: 2021-11-23
publish: true
draft: false
tags: ["aws", "ec2", "cloud"]
categories: ["blog"]
summary: "The new generation EC2 service is nitro based instance which require some configuration. In this tutorial I will go through all the requirement that you need to check or do."

---
				![Pasted image 20251218222004](/images/Pasted image 20251218222004.png)

EC2 server is virtual machine which running on hypervisor under AWS hardware. The new generation EC2 service is nitro based instance which require some configuration. In this tutorial I will go through all the requirement that you need to check or do.

Before starting this tutorial please see the following information from AWS doc regarding AWS Nitro System

> The AWS Nitro System is the underlying platform for our next generation of EC2 instances that enables AWS to innovate faster, further reduce cost for our customers, and deliver added benefits like increased security and new instance types.
>
> AWS has completely re-imagined our virtualization infrastructure. Traditionally, hypervisors protect the physical hardware and bios, virtualize the CPU, storage, networking, and provide a rich set of management capabilities. With the Nitro System, we are able to break apart those functions, offload them to dedicated hardware and software, and reduce costs by delivering practically all of the resources of a server to your instances.

Most of problem when changing instance type to nitro base support is the nitro base instance require ENA-attribute enabled, ENA module and NVME module installed on the instance and will cause failing status check if we force change the instance type without enabling ENA-attribute and the installing the module.

## prerequisites:

basic understanding of AWS EC2 service, AWS CLI and Linux bash command.

## Steps on how to resize AWS nitro-based instance type:

1. Create an Image of the current system  
2. Download the nitro instance check script and running it  
3. Check the ENA-attribute support is enable on your instance  
4. Resize your instance type to M5  
5. Start the instance and check if the instance up and running with status check 2/2  

## Create the AMI of the current system

![Pasted image 20251218222057](/images/Pasted image 20251218222057.png)

![Pasted image 20251218222120](/images/Pasted image 20251218222120.png)
By creating the AMI we can do a rollback if the changes that we made is not working as we expect. You can put the Image name and description and go ahead to create the Image. It will take a few minutes depends on the size of EBS volume attached to the instance.

## Download and Run the NitroInstanceChecks script

See the following description from AWS doc on what the script do:

The NitroInstanceChecks script checks your instance and provides a pass/fail status of these requirements:

- Verifies if the NVMe module is installed on your instance. If yes, then the script verifies that the module is loaded in the initramfs image.
- Verifies if the ENA module is installed on your instance.
- Analyzes /etc/fstab and looks for block devices being mounted using device names.

This script is supported on the following OS versions:

- Red Hat derivatives: Red Hat Linux, Red Hat Enterprise Linux, CentOS  
- Amazon Linux, Amazon Linux 2  
- Debian derivatives: Debian, Ubuntu  

You can download the script in this repository:  
https://github.com/awslabs/aws-support-tools/tree/master/EC2/NitroInstanceChecks

### Download the script

```bash
curl -o nitro_check_script.sh https://raw.githubusercontent.com/awslabs/aws-support-tools/master/EC2/NitroInstanceChecks/nitro_check_script.sh
````
![Pasted image 20251218222213](/images/Pasted image 20251218222213.png)
### Make the script executable

```bash
chmod +x nitro_check_script.sh
```
![Pasted image 20251218222232](/images/Pasted image 20251218222232.png)
### Execute the script

```bash
sudo ./nitro_check_script.sh
```
![Pasted image 20251218222256](/images/Pasted image 20251218222256.png)
## Check the ENA-attribute support is enable on your instance

```bash
aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[].Instances[].EnaSupport"
```

If you get empty response (`[ ]`) then it means it’s not enabled.

Please use the following command to stop the instance and enable ena-support using AWS CLI

```bash
aws ec2 stop-instances --instance-id ${INSTANCE_ID}
aws ec2 modify-instance-attribute --instance-id ${INSTANCE_ID} --ena-support
```

If you get response (`[true]`) it means the instance already ENA enabled and you can go ahead resize the instance.

## Resize your instance type to M5

Stop your instance and resize it from M4 to M5 using AWS cli

```bash
aws ec2 stop-instances --instance-id ${INSTANCE_ID}
aws ec2 modify-instance-attribute --instance-id ${INSTANCE_ID} --instance-type '{"Value": "m5a.2xlarge"}'
```

## Start the instance and check if the instance up and running with status check 2/2

```bash
aws ec2 start-instances --instance-id ${INSTANCE_ID}
```

## reference:

[https://aws.amazon.com/premiumsupport/knowledge-center/boot-error-linux-nitro-instance/](https://aws.amazon.com/premiumsupport/knowledge-center/boot-error-linux-nitro-instance/)