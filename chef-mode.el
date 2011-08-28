;;; chef-mode.el --- minor mode for editing an opscode chef repository

;; Copyright (C) 2011 Maciej Pasternacki

;; Author: Maciej Pasternacki <maciej@pasternacki.net>
;; Created: 28 Aug 2011
;; Version: 0.1
;; Keywords: chef knife

;;; Commentary:

;; This library defines a minor mode to work with Opscode Chef
;; (http://www.opscode.com/chef/) repository. It creates two
;; keybindings:

;; - C-c C-c (M-x chef-knife-dwim) - when editing part of chef
;;   repository (cookbook, data bag item, node/role/environment
;;   definition), uploads that part to the Chef Server by calling
;;   appropriate knife command
;; - C-c C-k (M-x knife) - runs a user-specified knife command

;; The library detects bundler and, if Gemfile is present on top-level
;; of the Chef repository, runs 'bundle exec knife' instead of plain
;; 'knife'.

;; If chef-use-rvm is non-nil, it talks with rvm.el
;; (https://github.com/senny/rvm.el) to use proper Ruby and gemset.

;;; Code:


(defvar chef-knife-command "knife"
  "Knife command to run")

(defvar chef-use-bundler t
  "Use `bundle exec knife' if Gemfile exists")

(defvar chef-use-rvm t
  "If non-nil, require rvm.el and call rvm-activate-corresponding-ruby on chef repo root before calling knife")

(defvar chef-mode-map (make-sparse-keymap)
  "Key map for chef-mode")

(define-key chef-mode-map (kbd "\C-c \C-k") 'knife)
(define-key chef-mode-map (kbd "\C-c \C-c") 'chef-knife-dwim)

(define-minor-mode chef-mode
  "Mode for interacting with Opscode Chef"
  nil chef-mode-map)

(defun turn-on-chef-mode ()
  "Enable chef-mode."
  (chef-mode 1))

(define-globalized-minor-mode global-chef-mode
  chef-mode turn-on-chef-mode)

(defun chef-root (&optional path)
  (when (null path)
    (setq path (or buffer-file-name
                   default-directory)))
  
  (cond
   ((not (file-directory-p path))
    (chef-root (concat (file-name-as-directory path) "..")))
   ((equal (expand-file-name path) (expand-file-name "~")) nil)
   ((equal (expand-file-name path) "/") nil)
   ((let ((ff (directory-files path)))
      (or (member ".chef" ff)
          (and (member "cookbooks" ff)
               (member "roles" ff)
               (member "config" ff))))
    (file-name-as-directory (expand-file-name path)))
   (t (chef-root (concat (file-name-as-directory path) "..")))))

(defun chef-run-knife (command &rest args)
  (let ((default-directory (or (chef-root)
                               (error "Not in chef repo!"))))
    (when chef-use-rvm
      (rvm-activate-corresponding-ruby))
    (with-current-buffer "*knife*"
      (toggle-read-only nil)
      (erase-buffer)
      (insert-string (concat "+ knife " command " "
                             (mapconcat 'identity args " ")
                             "\n"))
      (if (and chef-use-bundler (file-exists-p "Gemfile"))
          (apply 'call-process
                 "bundle" nil t
                 "bundle" "exec" chef-knife-command (cons command args))
        (apply 'call-process
               chef-knife-command nil t
               chef-knife-command (cons command args)))
      (toggle-read-only t)))
  (switch-to-buffer-other-window "*knife*" t)
  (fit-window-to-buffer))

(defun knife (command)
  "Run knife"
  (interactive "Command: knife ")
  (apply 'chef-run-knife (split-string-and-unquote command)))

(defun chef-knife-dwim ()
  "Upload currently edited thing to the Chef server.

Guesses whether you have "
  (interactive)
  (let ((b (current-buffer)))
    (save-some-buffers nil (lambda ()
                             (eq b (current-buffer)))))
  (let* ((default-directory (or (chef-root)
                                (error "Not in chef repo!")))
         (rpath (file-relative-name buffer-file-name default-directory)))
    (cond
     ((string-match "^\\(?:site-\\)?cookbooks/\\([^/]+\\)/" rpath)
      (print (match-string 1 rpath))
      (chef-run-knife "cookbook" "upload" (match-string 1 rpath)))
     ((string-match "^\\(role\\|node\\|environment\\)s/\\(.*\\)" rpath)
      (chef-run-knife (match-string 1 rpath) "from" "file" (match-string 2 rpath)))
     ((string-match "^data.bags/\\([^/]+\\)/\\(.*\\.yaml\\)" rpath)
      (chef-run-knife "data" "bag" "from" "yaml" (match-string 1 rpath) (match-string 2 rpath)))
     ((string-match "^data.bags/\\([^/]+\\)/\\(.*\\)" rpath)
      (chef-run-knife "data" "bag" "from" "file" (match-string 1 rpath) (match-string 2 rpath)))
     (t (error "Don't know how to upload %s to the Chef server" rpath)))))

;;; chef-mode.el ends here
