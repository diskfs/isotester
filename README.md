# iso image tester

This is a simple repo to compare creating a bootable iso image with standard linux utilities,
notably [genisoimage](https://linux.die.net/man/1/genisoimage), and [go-diskfs](https://github.com/diskfs/go-diskfs).

To compare, you do the following:

1. Clone this repo to get all the files you need.
1. Get the necessary binaries for booting and place them in `files/`.
1. Generate an iso image using the standard linux utilities.
1. Generate an iso image using go-diskfs.

To keep it simple, all you need to do is:

```
make generate
```

This will:

1. Get all of the binary dependencies - to run separately, `make deps`
1. Build the go builder - to run separately, `make build`
1. Generate an image `isos/linux.iso` via genisoimage - to run separately, `make generate-linux`
1. Generate an image `isos/go.iso` via the go binary - to run separately, `make generate-go`

To run either image in qemu:

```
make run-go
make run-linux
```
