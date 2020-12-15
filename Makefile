.PHONY: build clean run
.PHONY: generate generate-go generate-linux
.PHONY: run-go run-linux

SYSLINUX_VERSION ?= syslinux-6.03
ISOLINUXDIST ?= https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/$(SYSLINUX_VERSION).tar.gz
ISOLINUXTGZ ?= images/$(SYSLINUX_VERSION).tar.gz
ISOLINUXDIR ?= files/isolinux
IMAGESDIR ?= files/images
ISOLINUX ?= $(ISOLINUXDIR)/isolinux.bin
LDLINUX ?= $(ISOLINUXDIR)/ldlinux.c32
EFIBOOTDIST ?= https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.6/4.6.1/rhcos-4.6.1-x86_64-live.x86_64.iso
EFIBOOT ?= $(IMAGESDIR)/efiboot.img

ISOSDIR ?= dist/isos
GOISO ?= $(ISOSDIR)/go.iso
LINUXISO ?= $(ISOSDIR)/linux.iso

DISTDIR ?= dist
GOBUILDER ?= $(DISTDIR)/geniso

deps: $(ISOLINUX) $(LDLINUX) $(EFIBOOT)

$(ISOLINUXTGZ):
	curl -L $(ISOLINUXDIST) > $@

$(ISOLINUXDIR) $(IMAGESDIR):
	mkdir -p $@

$(ISOLINUX): $(ISOLINUXDIR) $(ISOLINUXTGZ)
	cat $(ISOLINUXTGZ) | tar -zxvf - -O $(SYSLINUX_VERSION)/bios/core/isolinux.bin > $@

$(LDLINUX): $(LDLINUXDIR) $(ISOLINUXTGZ)
	cat $(ISOLINUXTGZ) | tar -zxvf - -O $(SYSLINUX_VERSION)/bios/com32/elflink/ldlinux/ldlinux.c32 > $@

$(EFIBOOT): $(IMAGESDIR)
	curl -L $(EFIBOOTDIST) | 7z e -so IMAGES/EFIBOOT.IMG > $@

build: $(GOBUILDER)

$(DISTDIR):
	mkdir -p $@

$(GOBUILDER): $(DISTDIR)
	go build -o $@ .

clean:
	rm -rf build/*
	rm -f isos/*


generate: deps generate-go generate-linux
generate-go: $(GOISO)
generate-linux: $(LINUXISO)
$(GOISO): $(ISOSDIR) $(GOBUILDER)
	$(GOBUILDER) --out $@

$(LINUXISO): $(ISOSDIR)
	docker run --rm -v $$(pwd):/pwd ubuntu:20.04 sh -c "apt update && apt install -y genisoimage && \
	genisoimage  -V my-volume\
                -c isolinux/boot.cat\
                -b isolinux/isolinux.bin\
                -no-emul-boot\
                -boot-load-size 4\
                -boot-info-table\
                -eltorito-alt-boot\
                -e images/efiboot.img\
                -no-emul-boot\
                -o /pwd/$@ \
                /pwd/files/"

run-go: $(GOISO)
	qemu-system-x86_64 -boot d -cdrom $(GOISO) -m 512

run-linux: $(LINUXISO)
	qemu-system-x86_64 -boot d -cdrom $(LINUXISO) -m 512

