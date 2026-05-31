;; This is a sample Guix Home configuration which can help setup your
;; home directory in the same declarative manner as Guix System.
;; For more information, see the Home Configuration section of the manual.
(define-module (guix-home-config)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services ssh)
  #:use-module (gnu services)
  #:use-module (gnu packages)
  #:use-module (gnu system shadow)
  #:use-module (guix gexp))

(home-environment
  (services
   (append (list (service home-bash-service-type
                          (home-bash-configuration
                           (guix-defaults? #t)
                           (aliases '(("l" . "ls --color=auto")
                                      ("ls" . "ls --color=auto")
                                      ("la" . "ls -a --color=auto")
                                      ("ll" . "ls -l --color=auto")
                                      ("grep" . "grep --color=auto")))
                           (environment-variables '(("COLORTERM" . "truecolor")))
                           (variables '(("HISTSIZE" . "-1")
                                        ("HISTFILESIZE" . "-1")
                                        ("HISTCONTROL" . "ignoreboth,erasedups")
                                        ("PROMPT_COMMAND" . "history -a; $PROMPT_COMMAND")
                                        ("PROMPT_DIRTRIM" . "3")
                                        ("PS1" . "\\[\\e[34;1m\\]\\w\\[\\e[35;1m\\] > \\[\\e[0m\\]")))))

                 (service home-openssh-service-type
                          (home-openssh-configuration (authorized-keys (list (plain-file
                                                                              "pschaetz.pub"
                                                                              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINon0UfnQTLyeKOxYZ3qMEQ+fyf9adL76cJgvVUpTJoi Paul Schaetzle Desktop")))))

                 (service home-ssh-agent-service-type)

                 (service home-files-service-type
                          `((".guile" ,%default-dotguile)
                            (".Xdefaults" ,%default-xdefaults)))

                 (service home-xdg-configuration-files-service-type
                          `(("gdb/gdbinit" ,%default-gdbinit)
                            ("nano/nanorc" ,%default-nanorc))))

           %base-home-services)))

