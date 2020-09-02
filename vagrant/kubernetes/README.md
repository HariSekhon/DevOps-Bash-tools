Vagrant Kubernetes Lab
======================

#### Quickstart

Boots a 2 node Kubernetes cluster (1 master + 1 worker) and drops you straight in to the master shell to run `kubectl` commands

`make`

#### Details

Builds a Kubernetes cluster using `kubeadm` with one of the following configurations:

- 2 nodes - 1 master, 1 worker
- 3 nodes - 1 master, 2 workers
- 4 nodes - 3 masters, 1 worker
- 5 nodes - 3 masters, 2 workers

The hosts are intuitively named:

```
master1
master2
master3
worker1
worker2
```

You can boot whichever ones you want intuitively via

```
vagrant up <selection of nodes>
```

eg.

```
vagrant up master1 worker1
```

or use any one of the following script shortcuts to give you one of the above configurations:

```
./2nodes.sh
./3nodes.sh
./4nodes.sh
./5nodes.sh
```

Tear down the lab in the usual vagrant way:

```
vagrant destroy
```
