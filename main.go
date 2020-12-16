package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/diskfs/go-diskfs"
	"github.com/diskfs/go-diskfs/disk"
	"github.com/diskfs/go-diskfs/filesystem"
	"github.com/diskfs/go-diskfs/filesystem/iso9660"
)

func main() {
	outPath := flag.String("out", "lib-out.iso", "output ISO path")
	filesPath := flag.String("files", "files", "directory to add to the iso")

	flag.Parse()
	err := genISO(*filesPath, *outPath, 8712192)
	if err != nil {
		fmt.Printf("Failed to create iso: %s\n", err)
		os.Exit(1)
	}
}

// creates a new iso out of the directory structure at isoDir and writes it to outPath
func genISO(filesPath, outPath string, size int64) error {
	os.RemoveAll(outPath)
	d, err := diskfs.Create(outPath, size, diskfs.Raw)
	if err != nil {
		return err
	}

	d.LogicalBlocksize = 2048
	fspec := disk.FilesystemSpec{Partition: 0, FSType: filesystem.TypeISO9660, VolumeLabel: "my-volume"}
	fs, err := d.CreateFilesystem(fspec)
	if err != nil {
		return err
	}

	addFileToISO := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		p, err := filepath.Rel(filesPath, path)
		if err != nil {
			return err
		}

		if info.IsDir() {
			return fs.Mkdir(p)
		}

		content, err := ioutil.ReadFile(path)
		if err != nil {
			return err
		}

		rw, err := fs.OpenFile(p, os.O_CREATE|os.O_RDWR)
		if err != nil {
			return err
		}

		_, err = rw.Write(content)
		return err
	}
	if err := filepath.Walk(filesPath, addFileToISO); err != nil {
		return err
	}

	iso, ok := fs.(*iso9660.FileSystem)
	if !ok {
		return fmt.Errorf("not an iso9660 filesystem")
	}

	options := iso9660.FinalizeOptions{
		VolumeIdentifier: "my-volume",
		ElTorito: &iso9660.ElTorito{
			BootCatalog: "isolinux/boot.cat",
			Entries: []*iso9660.ElToritoEntry{
				{
					Platform:    iso9660.BIOS,
					Emulation:   iso9660.NoEmulation,
					BootFile:    "isolinux/isolinux.bin",
					LoadSegment: 4,
				},
				{
					Platform:  iso9660.EFI,
					Emulation: iso9660.NoEmulation,
					BootFile:  "images/efiboot.img",
				},
			},
		},
	}
	err = iso.Finalize(options)
	if err != nil {
		return err
	}

	return nil
}
