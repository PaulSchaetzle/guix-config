;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.

;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu))
(use-system-modules accounts)
(use-package-modules admin file-systems)
(use-service-modules avahi
                     containers
                     cups
                     desktop
                     networking
                     samba
                     shepherd
                     ssh
                     xorg)

(operating-system
  (locale "en_US.utf8")
  (timezone "Europe/Berlin")
  (keyboard-layout (keyboard-layout "de" "us"))
  (host-name "guix")

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "pschaetz")
                  (comment "Paul Schaetzle")
                  (group "users")
                  (home-directory "/home/pschaetz")
                  (supplementary-groups '("wheel" "netdev" "audio" "video"
                                          "cgroup")))
                (user-account
                  (name "jellyfin")
                  (group "users")
		  ; home is required for podman to work
                  (home-directory "/home/jellyfin")
                  (shell (file-append shadow "/sbin/nologin"))
                  (system? #t)
                  (supplementary-groups '("cgroup"))) %base-user-accounts))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (cons* (service elogind-service-type)
          (service openssh-service-type)
          (service avahi-service-type)
          (service dhcpcd-service-type)
          (service nftables-service-type
                   (nftables-configuration (ruleset (plain-file
                                                     "nftables.conf"
                                                     "
                            flush ruleset
                            table inet filter {
                            	chain input {
                            		type filter hook input priority filter; policy drop;
                            		ct state invalid drop
                            		ct state { established, related } accept
                            		iif \"lo\" accept
                            		iif != \"lo\" ip daddr 127.0.0.0/8 drop
                            		iif != \"lo\" ip6 daddr ::1 drop
                            		ip protocol icmp accept
                            		ip6 nexthdr ipv6-icmp accept
                            		tcp dport 22 accept
                                udp dport mdns accept
                                # samba
                                tcp dport 445 accept
                                # jellyfin
                                tcp dport 8096 accept
                                udp dport 7359 accept
                            		reject
                            	}

                            	chain forward {
                            		type filter hook forward priority filter; policy drop;
                            	}

                            	chain output {
                            		type filter hook output priority filter; policy accept;
                            	}
                            }
                           "))))
          (service samba-service-type
                   (samba-configuration (enable-smbd? #t)
                                        (config-file (plain-file "smb.conf"
                                                      "
                            [global]
                            map to guest = Bad User
                            logging = syslog@1

                            [Test-Share]
                            browsable = yes
                            path = /mnt/zfs_pool/test_share
                            read only = no
                            guest ok = yes
                            "))))
          (service rootless-podman-service-type
                   (rootless-podman-configuration (subgids (list (subid-range (name
                                                                               "pschaetz"))
                                                                 (subid-range (name
                                                                               "jellyfin"))))
                                                  (subuids (list (subid-range (name
                                                                               "pschaetz"))
                                                                 (subid-range (name
                                                                               "jellyfin"))))))
          (service oci-service-type
                   (oci-configuration (runtime 'podman)))

          (simple-service 'jellyfin-oci oci-service-type
                          (oci-extension (containers (list (oci-container-configuration
                                                            (network "host")
                                                            (user "jellyfin")
                                                            (extra-arguments '("--userns=keep-id"))
                                                            (requirement '(zpool-import networking))
                                                            (respawn? #t)
                                                            (image
                                                             "jellyfin/jellyfin:latest")
                                                            (ports '(("8096" . "8096")
                                                                     ("7359" . "7359")))
                                                            (volumes '("jellyfin-cache:/cache"
                                                                       "jellyfin-config:/config"
                                                                       "/mnt/zfs_pool/media:/media")))))))
          (simple-service 'zpool-import shepherd-root-service-type
                          (list (shepherd-service (provision '(zpool-import))
                                                  (requirement '(udev))
                                                  (one-shot? #t)
                                                  (start #~(lambda _
                                                             (system* #$(file-append
                                                                         zfs
                                                                         "/sbin/zpool")
                                                              "import" "-a"))))))
          (service ntp-service-type)

          ;; This is the default list of services we
          ;; are appending to.
          %base-services))

  (kernel-loadable-modules (list (list zfs "module")))

  (packages (append (list zfs) %base-packages))

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid "0b502881-01ed-49cd-96bd-6e381a8ee4a7")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "ABA1-2BE6"
                                       'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device (uuid "fc8d0217-10e9-4882-9323-2ad0559c2c69"
                                       'ext4))
                         (type "ext4")) %base-file-systems)))
