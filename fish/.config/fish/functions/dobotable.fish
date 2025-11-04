function dobotable --wraps="sudo dd if=iso of=device bs=4M status=progress conv=fdatasync" --description "alias dobotable sudo dd if=iso of=device bs=4M status=progress conv=fdatasync"
  argparse "i/iso=" "d/device=" -- $argv
  or return


  if not test -f "$_flag_iso"
    echo "Error: ISO file '$_flag_iso' does not exist." >&2
    return 1
  end

  if not test -b "$_flag_device"
    echo "Error: Device '$_flag_device' does not exist." >&2
    return 1
  end

  sudo dd bs=4M if="$_flag_iso" of="$_flag_device" status=progress oflag=sync
end
