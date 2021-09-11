# Rancher

[![Build Status](https://drone-publish.rancher.io/api/badges/rancher/rancher/status.svg?branch=master)](https://drone-publish.rancher.io/rancher/rancher)
[![Docker Pulls](https://img.shields.io/docker/pulls/rancher/rancher.svg)](https://store.docker.com/community/images/rancher/rancher)
[![Go Report Card](https://goreportcard.com/badge/github.com/rancher/rancher)](https://goreportcard.com/report/github.com/rancher/rancher)

Rancher is an open source container management platform built for organizations that deploy containers in production. Rancher makes it easy to run Kubernetes everywhere, meet IT requirements, and empower DevOps teams.

> Looking for Rancher 1.6.x info?  [Click here](https://github.com/rancher/rancher/blob/master/README_1_6.md)

## Latest Release

* Latest - v2.6.0 -  Read the full release [notes](https://github.com/rancher/rancher/releases/tag/v2.6.0).

## Installation

```console
  
$ vagrant up

$ ssh-add ~/.vagrant.d/insecure_private_key

$ cd ansible

$ ansible-playbook -i inventory deploy.yaml

```   	

## Upgrade

```console
$ cd ansible

$ ansible-playbook -i inventory upgrade.yaml

```   	

## Test

Open Browser https://10.240   
       
