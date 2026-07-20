#!/bin/bash -x
# Clinton Webb, 2024
#
#  When new storage devices (disks) added to VM's this script can be used to add it to a volume group. It is especially used without 
#  knowing the details of the disk presented to the VM.  So it will attempt to find any device that is not in use, and attempt to add it 
#  to the volume group.
#

# If no volume group is specified
zVG=${1:-vg_sys}

# Get the list of devices, and ignore sda as it is normally the intitial boot device.
lsblk | grep disk | grep -v 'sda' | awk '{print $1}' | while read -r zDEV; do

  echo "Checking: /dev/$zDEV"
  # Check that it isn't already mounted somewhere
  findmnt -n -R --source /dev/$zDEV &> /dev/null
  if [[ $? -gt 0 ]]; then

    pvdisplay /dev/$zDEV &> /dev/null
    if [[ $? -gt 0 ]]; then

      pvcreate /dev/$zDEV
      if [[ $? -eq 0 ]]; then

        vgdisplay $zVG &> /dev/null
        if [[ $? -gt 0 ]]; then
          # VG doesn't exist, so need to create (and add the disk)
          vgcreate $zVG /dev/$zDEV
          if [[ $? -eq 0 ]]; then
            echo "OK – added /dev/$zDEV to $zVG"
          fi
        else
          # VG already exists, so we just extending it.
          vgextend $zVG /dev/$zDEV
          if [[ $? -eq 0 ]]; then
            echo "OK – added /dev/$zDEV to $zVG"
          fi
        fi
      fi
    fi
  fi
done

