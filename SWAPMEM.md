# Move mostly all docker memory to swap

run with sudo script:  

```sh
sudo python setup/fedora/docker-reduce-ram.py
```

# SSD-backed swap on Fedora / Btrfs

Create a 48 GiB swapfile on your drive. Run these commands once, stopping if
any command fails. If you already completed them, skip to verification.

1. Create a separate Btrfs subvolume for swap. Exclude it from snapshots.

   ```sh
   sudo btrfs subvolume create /var/swap
   ```

2. Allocate and format the swapfile. Btrfs handles the required NOCOW settings.
   Change `48G` if you want a different size; make sure the drive has enough space.

   ```sh
   sudo btrfs filesystem mkswapfile --size 48G /var/swap/swapfile
   ```

3. Enable it immediately. Linux automatically uses it when needed.

   ```sh
   sudo swapon /var/swap/swapfile
   ```

4. Enable it at every boot:

   ```sh
   sudoedit /etc/fstab
   ```

   Add this line once, then save:

   ```fstab
   /var/swap/swapfile none swap defaults,nofail 0 0
   ```

   Check the file and reload systemd. Fix any reported fstab errors before rebooting.

   ```sh
   sudo findmnt --verify --verbose
   sudo systemctl daemon-reload
   ```

5. Optional: remove RAM-backed zram if you want only disk-backed swap.
   This also removes `zram-generator-defaults`. Existing zram can remain active
   until you reboot.

   ```sh
   sudo dnf remove zram-generator
   ```

6. After saving your work, reboot and verify:

   ```sh
   sudo reboot
   ```

   ```sh
   swapon --show
   free -h
   ```

   Expect `/var/swap/swapfile` with about 48 GiB. If you removed zram,
   `/dev/zram0` should be absent. `USED=0B` is normal when disk swap is not needed;
   priority `-1` is valid. Swap adds capacity, but is slower than RAM.

Reference: [Btrfs swapfile documentation](https://btrfs.readthedocs.io/en/latest/Swapfile.html).
