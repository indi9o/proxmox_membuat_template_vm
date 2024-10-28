#!/bin/bash

# Cek apakah file image sudah ada
if [ ! -f jammy-server-cloudimg-amd64.img ]; then
    echo "File image tidak ditemukan, mengunduh image..."
    wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
else
    echo "File image sudah ada, tidak perlu mengunduh ulang."
fi

# Resize image menjadi 10GB
qemu-img resize jammy-server-cloudimg-amd64.img 10G

# Install libguestfs-tools jika belum terinstal
if ! command -v virt-customize &> /dev/null; then
    echo "libguestfs-tools tidak ditemukan, menginstal libguestfs-tools..."
    apt install -y libguestfs-tools
else
    echo "libguestfs-tools sudah terinstal."
fi

# Customize image dengan qemu-guest-agent
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent --truncate /etc/machine-id

# Membuat VM di Proxmox
qm create 9999 --name ubuntu-jammy --core 1 --memory 1024 --net0 virtio,bridge=vmbr0

# Import image disk ke VM
qm disk import 9999 jammy-server-cloudimg-amd64.img local-zfs

# Set hardware VM (SCSI, boot, agent, serial console, VGA)
qm set 9999 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9999-disk-0
qm set 9999 --boot c --bootdisk scsi0
qm set 9999 --agent 1
qm set 9999 --serial0 socket
qm set 9999 --vga serial0

# Izinkan hotplug network, USB, dan disk
qm set 9999 --hotplug network,usb,disk

# Convert VM menjadi template
qm template 9999

echo "Template VM berhasil dibuat."