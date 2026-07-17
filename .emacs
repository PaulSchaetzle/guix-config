(use-package emacs
  :hook
  ((prog-mode . imenu-add-menubar-index)
   (prog-mode . (lambda () (setq-local imenu-auto-rescan t))))
  :custom
  (tab-always-indent 'complete) 
  (display-line-numbers-type 'relative)
  (fill-column 80)
  (display-fill-column-indicator-column t)
  (backup-directory-alist '(("." . "~/.emacs.d/backups/")))
  (auto-revert-remote-files t)
  (gdb-restore-window-configuration-after-quit t)
  (gdb-many-windows t)
  (major-mode-remap-alist '(
			    (c-mode . c-ts-mode)
			    (c++-mode . c++-ts-mode)
			    (python-mode . python-ts-mode)
			    (cmake-mode . cmake-ts-mode)))
  ;; Required by vertico
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  (save-interprogram-paste-before-kill 256)
  (global-auto-revert-non-file-buffers t)
  (Man-notify-method 'aggressive)
  :config
  (scroll-bar-mode -1)
  (desktop-save-mode)
  (global-display-line-numbers-mode)
  (global-auto-revert-mode)
  (context-menu-mode)
  (savehist-mode)
  (defun project-gdb ()
    (interactive)
    (let ((default-directory
           (project-root (project-current t))))
      (select-frame-set-input-focus (make-frame))
      (call-interactively #'gdb)))

  (defun my-ibuffer-project-groups ()
    "Generate ibuffer saved filter groups grouped by project."
    (let ((projects
           (delq nil
		 (delete-dups
                  (mapcar (lambda (buf)
                            (with-current-buffer buf
                              (project-current)))
                          (buffer-list))))))

      `(("Projects"
	 ,@(mapcar
            (lambda (proj)
              (let ((root (project-root proj)))
		`(,(project-name proj)
                  (directory . ,(expand-file-name root)))))
            (sort projects
                  (lambda (a b)
                    (> (length (project-root a))
                       (length (project-root b)))))))))))

(use-package package
  :init
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/"))
  :config
  (package-initialize))

(use-package modus-themes
  :ensure t
  :demand t
  :init
  (load-theme 'modus-operandi t))

(use-package evil
  :ensure t
  :custom
  (evil-want-C-u-scroll t)
  (evil-want-integration t)
  (evil-want-C-u-delete t)
  (evil-want-keybinding nil)
  :hook
  ((evil-insert-state-entry . 
			    (lambda ()
			      (setq display-line-numbers-type 'absolute)
			      (display-line-numbers-mode)))
   (evil-insert-state-exit .
			   (lambda ()
			     (setq display-line-numbers-type 'relative)
			     (display-line-numbers-mode))))
  :config
  (evil-set-undo-system 'undo-redo)
  (evil-set-leader '(normal visual replace motion operator) (kbd "SPC"))
  (evil-define-key 'normal 'global (kbd "<leader>b") 'ibuffer) 
  (evil-define-key 'insert 'global (kbd "TAB") 'completion-at-point)
  (evil-define-key 'normal 'global (kbd "<leader>e") 'project-dired)
  (evil-define-key 'normal 'global (kbd "<leader>.") 'dired-jump)
  (evil-define-key 'normal 'global (kbd "<leader>f") 'project-find-file)
  (evil-define-key 'normal 'global (kbd "<leader>i") 'imenu)
  (evil-define-key 'normal 'global (kbd "<leader>d") (lambda ()
						       (interactive)
						       (flymake-show-diagnostics-buffer)
						       (other-window 1)))
  (evil-define-key 'normal 'global (kbd "<leader>t") 'eat-project-other-window)
  (evil-define-key 'normal 'global (kbd "<leader>T") (lambda ()
						       (interactive)
						       (select-frame-set-input-focus (make-frame))
						       (eat-project)))
  (evil-define-key 'normal 'global (kbd "gs") 'evil-first-non-blank)
  (evil-define-key 'normal 'global (kbd "gh") 'evil-beginning-of-line)
  (evil-define-key 'normal 'global (kbd "gl") 'evil-end-of-line)
  (evil-define-key '() 'global (kbd "C-x p a") #'project-gdb)
  (evil-define-key 'normal 'global (kbd "<leader>o c") 'org-capture)
  (evil-define-key 'normal 'global (kbd "<leader>o a") 'org-agenda)
  (evil-mode))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init))

(use-package evil-surround
  :after evil
  :ensure t
  :config
  (global-evil-surround-mode))

(use-package evil-textobj-tree-sitter
  :after evil
  :config
  (define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))
  :ensure t)

(use-package avy
  :ensure t
  :config
  (evil-define-key 'normal 'global
    (kbd "RET") #'avy-goto-char-timer)
  (evil-define-key 'normal 'global
    (kbd "gw") #'avy-goto-char-timer))

(use-package magit
  :config
  (evil-define-key 'normal 'global (kbd "<leader>B") 'magit-blame-addition) 
  :ensure t)

(use-package ediff
  :custom
  (ediff-window-setup-function 'ediff-setup-windows-plain))

(use-package which-key
  :ensure t
  :config
  (which-key-mode))

(use-package vertico
  :ensure t
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode))
   
(use-package corfu
  :ensure t
  :config
  (global-corfu-mode))

(use-package cape
  :ensure t
  :hook
  ((completion-at-point-functions . cape-dabbrev)
   (completion-at-point-functions . cape-file)
   (completion-at-point-functions . cape-elisp-block)))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring

(use-package tramp
  :custom
  (tramp-verbose 0)
  :config
  (tramp-enable-method 'toolbox)
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path)
  (add-to-list 'tramp-connection-properties
               (list (regexp-quote "/toolbox:")
                     "remote-shell" "/bin/bash")))

(use-package eat
  :ensure t
  :config
  (eat-eshell-mode)
  (setq eshell-visual-commands '()))

(use-package rainbow-delimiters
  :ensure t
  :hook
  ((c-ts-mode . rainbow-delimiters-mode)
   (c++-ts-mode . rainbow-delimiters-mode)
   (python-mode . rainbow-delimiters-mode)
   (emacs-lisp-mode . rainbow-delimiters-mode)
   (scheme-mode . rainbow-delimiters-mode)))

(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode))

(use-package org-mode
  :defer t
  :hook
  ((org-mode . org-indent-mode)
   (org-mode . refill-mode)
   (org-mode . flyspell-mode))
  :custom
  (org-log-done 'time)
  (org-agenda-files '("~/org"))
  (org-capture-templates
   '(
     ("n" "Note" entry (file+headline "~/org/notes.org" "Notes")
      "** %?"
      :empty-lines 0)
     ("a" "Appointment" entry (file+olp+datetree "~/org/agenda.org" "Appointments")
      "** %^T %?"
      :empty-lines 0)
     ("g" "General To-Do" entry (file+headline "~/org/todos.org" "General Tasks")
      "* TODO [#B] %?\n:PROPERTIES:\n:CREATED: %U\n:SCHEDULED: %T\n:END:\n"
      :empty-lines 0)
     ("c" "Code To-Do" entry (file+headline "~/org/todos.org" "Code related Tasks")
      "* TODO [#B] %?\n:PROPERTIES:\n:CREATED: %U\n:SCHEDULED: %T\n:END:\n%i\n%a\nProposed Solution:"
      :empty-lines 0)))
  (org-babel-load-languages
   '(
     (emacs-lisp . t)
     (dot . t)
     (C . t)
     (shell . t)
     (python . t)))
  :config
  (add-to-list 'org-latex-packages-alist '("AUTO" "babel")))

(use-package cmake-mode
  :ensure t)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :custom
  (markdown-code-lang-modes '(
			      ("python" . python-ts-mode)
			      ("json" . json-ts-mode)
			      ("yaml" . yaml-ts-mode)))
  :init (setq markdown-command "multimarkdown"))

(use-package kbd-mode
  :vc (:url "https://github.com/kmonad/kbd-mode" :rev :newest))

(use-package geiser-guile
  :ensure t)

(use-package guix
  :ensure t)

(use-package yaml-ts-mode
  :mode "\\.ya?ml\\'")

(use-package eglot
  :ensure t
  :hook
  ((c-ts-mode . eglot-ensure)
   (c++-ts-mode . eglot-ensure)
   (python-ts-mode . eglot-ensure)
   (cmake-mode . eglot-ensure))
  :config
  (evil-define-key 'normal 'global (kbd "<leader>r") 'eglot-rename)
  (evil-define-key 'normal 'global (kbd "<leader>a") 'eglot-code-actions)
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c++-ts-mode) . ("clangd")))
  (add-to-list 'eglot-server-programs
	       '(python-mode . ("toolbox" "run" "-c" "ubuntu-toolbox-26.04" "jedi-language-server")))
  (add-to-list 'eglot-server-programs
	       '(cmake-mode . ("toolbox" "run" "-c" "ubuntu-toolbox-26.04" "neocmakelsp" "stdio"))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("7e98dc1aa7f5db0557691da690c38d55e83ddd33c6d268205d66e430d57fb982"
     "6dcf1ca4c7432773084b9d52649ee5eb2c663131c4c06859f648dea98d9acb3e"
     "10e330880269244ae45ae9e02fe6f55766da9e15036e7c7f07d7ce228195deb5" default))
 '(gud-gdb-command-name
   "~/zephyr-sdk-1.0.1/arm-zephyr-eabi/bin/arm-zephyr-eabi-gdb -i=mi")
 '(package-selected-packages
   '(avy cape cmake-mode company corfu eat eglot evil-collection evil-surround
	 fireplace geiser-guile guix kbd-mode magit markdown-mode modus-themes
	 orderless rainbow-delimiters vertico))
 '(package-vc-selected-packages '((kbd-mode :url "https://github.com/kmonad/kbd-mode")))
 '(safe-local-variable-values
   '((evil-shift-width . 8)
     (gdb-command-name
      . "~/zephyr-sdk-1.0.1/arm-zephyr-eabi/bin/arm-zephyr-eabi-gdb"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
