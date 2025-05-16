# About athenz-distribution repository

The documents describe the varieties of use-cases to implement authorization between pods inside a cluster.

# Introduction

[Athenz](http://www.athenz.io) is an open-source project, currently a CNCF sandbox project, that provides:  
- **Authentication** using SPIFFE-compatible X.509 certificates or OAuth 2.0-based access tokens.  
- **Authorization** through role-based access control (RBAC) for cloud workloads, including Kubernetes.  

# Why Athenz?

In multi-cluster or multi-cloud environments, precise and frequently configurable access control policies are crucial. Athenz simplifies this process with:  
- **Web UI, CLI, and REST API** for managing policies.  
- **Automated deployment** of policies to workloads via Athenz agents.  

## Getting Started with Athenz  

Athenz is a powerful solution, but getting started should be straightforward!
Many new users find the initial setup complex, making experimentation difficult.  

This repository is here to **simplify the process** and help you:  
- **Set up Athenz quickly** with step-by-step guidance.  
- **Understand core concepts** through practical examples.  
- **Integrate Athenz with Kubernetes and Envoy proxy** seamlessly.  

Start exploring today and take full control of your cloud access management with Athenz!  

# Athenz packages
  
- [List of Athenz package distribution](docs/DISTRIBUTIONS.md)

# Learn More

Visit the official Athenz website: [www.athenz.io](http://www.athenz.io)  

## Learn how to use Athenz in practice

- [How to generate keys and certificates](CERTIFICATES.md)
 
- [CLI instruction](docs/CLI.md)
 
- [How to generate keys and retrieve certificates (**Identity Provisioning**)](docs/IDENTITYPROVISIONING.md)

- [Envoy Ambassador Instruction for Kubernetes](docs/ENVOY.md)
 
- [Showcases for Kubernetes](docs/SHOWCASES_KUBERNETES.md)

