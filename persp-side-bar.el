;;; persp-side-bar.el --- Sidebar for perspective.el -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Omura Shuto

;; Author: Omura Shuto <somura-vanilla@so-icecream.com>
;; Maintainer: Omura Shuto <somura-vanilla@so-icecream.com>
;; URL: https://github.com/so-vanilla/persp-side-bar
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1") (perspective "2.0"))
;; Keywords: convenience, frames

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; persp-side-bar provides a sidebar window that displays all perspectives
;; registered in perspective.el.  The current perspective is highlighted,
;; and you can switch perspectives by clicking or pressing RET on the name.
;;
;; Features:
;; - Display all perspectives in a side window
;; - Highlight the current perspective
;; - Quick navigation between perspectives
;; - Auto-refresh when perspectives change
;; - Optional auto-show when creating new perspective
;;
;; Usage:
;;   M-x persp-side-bar-show    - Show the sidebar
;;   M-x persp-side-bar-toggle  - Toggle the sidebar
;;   M-x persp-side-bar-close   - Close the sidebar
;;   M-x persp-side-bar-focus   - Focus on the sidebar
;;
;; Keybindings in the sidebar:
;;   n, j  - Next perspective
;;   p, k  - Previous perspective
;;   RET   - Switch to perspective at point
;;   SPC   - Switch to perspective at point
;;   g     - Refresh sidebar
;;   r     - Reset sidebar width
;;   q     - Close sidebar

;;; Code:

(require 'perspective)

;; Variables
(defvar persp-side-bar-buffer-name "*Persp Side Bar*"
  "Name of the perspective sidebar buffer.")

(defvar persp-side-bar-window nil
  "Window displaying the perspective sidebar buffer.")

(defcustom persp-side-bar-auto-show-on-new t
  "Whether to automatically show sidebar when creating new perspective."
  :type 'boolean
  :group 'perspective)

;; Core functions
(defun persp-side-bar-show ()
  "Show perspective sidebar."
  (interactive)
  (let ((buffer (get-buffer-create persp-side-bar-buffer-name)))
    (with-current-buffer buffer
      (persp-side-bar--render-buffer))
    (setq persp-side-bar-window
          (display-buffer buffer '((display-buffer-in-side-window)
                                   (side . left)
                                   (slot . 0)
                                   (window-width . 30))))
    (select-window persp-side-bar-window)))

(defun persp-side-bar-toggle ()
  "Toggle perspective sidebar."
  (interactive)
  (let ((buffer (get-buffer persp-side-bar-buffer-name)))
    (if (and buffer (get-buffer-window buffer))
        (persp-side-bar-close)
      (persp-side-bar-show))))

(defun persp-side-bar-close ()
  "Close perspective sidebar."
  (interactive)
  (let ((buffer (get-buffer persp-side-bar-buffer-name)))
    (when buffer
      (let ((window (get-buffer-window buffer)))
        (when window
          (delete-window window)
          (setq persp-side-bar-window nil))))))

(defun persp-side-bar-focus ()
  "Focus on perspective sidebar."
  (interactive)
  (let ((buffer (get-buffer persp-side-bar-buffer-name)))
    (if (and buffer (get-buffer-window buffer))
        (select-window (get-buffer-window buffer))
      (persp-side-bar-show))))

(defun persp-side-bar-resize ()
  "Reset perspective sidebar size."
  (interactive)
  (let ((buffer (get-buffer persp-side-bar-buffer-name)))
    (when buffer
      (let ((window (get-buffer-window buffer)))
        (when window
          (with-selected-window window
            (window-resize window (- 30 (window-width)) t)))))))

;; Internal functions
(defun persp-side-bar--render-buffer ()
  "Render the perspective list in sidebar buffer."
  (let ((inhibit-read-only t)
        (keymap (persp-side-bar--create-keymap))
        (current-persp (persp-current-name))
        (all-persps (persp-names)))
    (erase-buffer)
    (insert "Perspective Side Bar\n")
    (insert "====================\n\n")
    (if all-persps
        (dolist (persp all-persps)
          (if (string= persp current-persp)
              ;; カレントperspectiveをハイライト
              (insert (propertize (format "► %s\n" persp)
                                  'face 'highlight))
            (insert-button persp
                           'action `(lambda (button)
                                      (persp-switch ,persp))
                           'follow-link t)
            (insert "\n")))
      (insert "No perspectives\n"))
    (goto-char (point-min))
    (setq buffer-read-only t)
    (use-local-map keymap)))

(defun persp-side-bar--highlight-current ()
  "Update highlight for current perspective."
  (when (and persp-side-bar-window
             (window-live-p persp-side-bar-window))
    (with-current-buffer (window-buffer persp-side-bar-window)
      (persp-side-bar--render-buffer))))

(defun persp-side-bar--create-keymap ()
  "Create keymap for perspective sidebar."
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap "n" 'persp-next)
    (define-key keymap "j" 'persp-next)
    (define-key keymap "p" 'persp-prev)
    (define-key keymap "k" 'persp-prev)
    (define-key keymap (kbd "RET") 'persp-side-bar-select-current)
    (define-key keymap (kbd "SPC") 'persp-side-bar-select-current)
    (define-key keymap "q" 'persp-side-bar-close)
    (define-key keymap "r" 'persp-side-bar-resize)
    (define-key keymap "g" 'persp-side-bar-refresh)
    keymap))

(defun persp-side-bar-select-current ()
  "Select perspective at current line in sidebar buffer."
  (interactive)
  (let ((persp-name (thing-at-point 'symbol)))
    (when (and persp-name (member persp-name (persp-names)))
      (persp-switch persp-name))))

(defun persp-side-bar-refresh ()
  "Refresh the sidebar content and update highlight."
  (interactive)
  (when (and persp-side-bar-window
             (window-live-p persp-side-bar-window))
    (with-current-buffer (window-buffer persp-side-bar-window)
      (persp-side-bar--render-buffer))))

(defun persp-side-bar-on-new-perspective ()
  "Handle new perspective creation - show sidebar if enabled."
  ;; 元のウィンドウを記憶
  (let ((original-window (selected-window)))
    ;; perspective切り替えが完了するまで少し待機
    (run-with-idle-timer 0.01 nil
                         (lambda ()
                           (if persp-side-bar-auto-show-on-new
                               (progn
                                 ;; サイドバー表示（内部でレンダリングも実行される）
                                 (persp-side-bar-show)
                                 ;; 元のウィンドウにフォーカスを戻す
                                 (when (window-live-p original-window)
                                   (select-window original-window)))
                             ;; 自動表示が無効の場合はリフレッシュのみ
                             (persp-side-bar-refresh))))))

;; Auto-refresh when perspective changes
(advice-add 'persp-switch :after
            (lambda (&rest _) (persp-side-bar-refresh)))

;; Phase 1: 基本的なperspective操作監視
(advice-add 'persp-new :after
            (lambda (&rest _) (persp-side-bar-on-new-perspective)))

(advice-add 'persp-kill :after
            (lambda (&rest _) (persp-side-bar-refresh)))

(advice-add 'persp-rename :after
            (lambda (&rest _) (persp-side-bar-refresh)))

;; Phase 2: 追加のperspective操作監視
(advice-add 'persp-next :after
            (lambda (&rest _) (persp-side-bar-refresh)))

(advice-add 'persp-prev :after
            (lambda (&rest _) (persp-side-bar-refresh)))

(advice-add 'persp-switch-last :after
            (lambda (&rest _) (persp-side-bar-refresh)))

(advice-add 'persp-kill-others :after
            (lambda (&rest _) (persp-side-bar-refresh)))

(advice-add 'persp-state-load :after
            (lambda (&rest _) (persp-side-bar-refresh)))

(advice-add 'persp-state-restore :after
            (lambda (&rest _) (persp-side-bar-refresh)))

(provide 'persp-side-bar)
;;; persp-side-bar.el ends here
