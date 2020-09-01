Vagrant Kubernetes Lab
======================

Builds a Kubernetes cluster using `kubeadm` of one of the following configurations:

- 2 nodes - 1 master, 1 worker
- 3 nodes - 1 masters, 2 workers
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

or use any one of the scripts:

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
