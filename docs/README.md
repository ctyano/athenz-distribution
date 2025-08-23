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

![System Structure](https://www.plantuml.com/plantuml/png/TPFTpjCm38RFSnLMptS9c_R3oGH8Y86G-15Aci0YTKsLEeCLxTvnd6JjkksWt-VOhv-yiRnrZz9ZE3MYCRyGq86tluy8sdfJetMj4B96vw7QuD6q0tpkZQz0zX0e4FIdbhs1wejHiFNkJwcg58-2tBvxj-TwtLWXwiO53TNRe8nl3PgO3Zr6n3y1K4klIoCtIGwv1j0wJTYKMWIRFEKQmBTYT_-32vRpryVEuTGloEWv-nuU25_V7nX1mfSCl6FW8-DJPk1BXbRSgzMjMKkKQZgxDziqbymcGp_JhT_ReYrEjPhey9KEHzsr-A9lvingqwB5owBpxcnrVcINhPGdxhCAFcGLNr5Qdd5bmAFpTf1npIByxuN9SfYXDrCX7EWfcHu9mvtqe-bTyBMPgdpEFVD0QqYsqqRERjrn2JPTnvIaPCPLYBZyi5pTrZp_XoNbWYrbtdBwAEJr4O727DFmn_X4SJveDPOmdj9nDOuoEIaAmKEOdrRZgqTvdfTOcrR7N_n_)
<!--
@startuml
left to right direction

actor "Athenz User" as user
usecase "Web Browser" as browser
usecase "Athenz CLI" as cli

cloud "Kubernetes cluster" {
  card "Athenz" as athenz {
    node "athenz-ui" as u {
      [Athenz UI] as ui
    }
    node "athenz-zms-server" as z {
      [Athenz ZMS] as zms
    }
    node "athenz-zts-server" as t {
      [Athenz ZTS] as zts
    }
    node "athenz-db" as db {
      database "Athenz DB" {
        [zms_server\ndatabase] as zmsdb
        [zts_server\ndatabase] as ztsdb
      }
    }
  }
  node "athenz-identity-provider" as p {
    [Athenz Identity Provider] as provider
  }
  node "athenz-authorization-proxy" as az {
    [Athenz Authorization Server] as authz
    [Athenz Resource Server] as resource
  }
  node "athenz-client" as c {
    [Athenz Client App] as client
  }
}

user => browser
browser ==> ui
user => cli
cli => zms

ui ==> zms
zts ==> zms
zms ===> zmsdb
zts ==> ztsdb

zts => provider
client ==> zts
authz ==> zts
authz => resource
client ==> authz

@enduml
-->

## Getting Started with Athenz  

Athenz is a powerful solution, but getting started should be straightforward!
Many new users find the initial setup complex, making experimentation difficult.  

This repository is here to **simplify the process** and help you:  
- **Set up Athenz quickly** with step-by-step guidance.  
- **Understand core concepts** through practical examples.  
- **Integrate Athenz with Kubernetes and Envoy proxy** seamlessly.  

Start exploring today and take full control of your cloud access management with Athenz!  

# Athenz packages
  
- [List of Athenz package distribution](DISTRIBUTIONS.md)

# Learn More

Visit the official Athenz website: [www.athenz.io](http://www.athenz.io)  

## Learn how to use Athenz in practice

- [How to generate keys and certificates](CERTIFICATES.md)
 
- [CLI instruction](CLI.md)
 
- [How to generate keys and retrieve certificates (**Identity Provisioning**)](IDENTITYPROVISIONING.md)

- [Envoy Ambassador Instruction for Kubernetes](ENVOY.md)
 
- [Showcases for Kubernetes](SHOWCASES_KUBERNETES.md)

