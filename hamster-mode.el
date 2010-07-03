;;; hamster-mode.el --- Hamster scripts editing for Emacs
;; $Id: hamster-mode.el,v 1.3 2005/12/01 22:42:24 fhaun Exp $

;; Copyright (C) 2000, 2002, 2005 Frank Haun.

;; Author: Frank Haun <fh AT fhaun DOT de>

;; Keywords: languages

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Major Mode for editing hamster scripts (*.hsc, *.hsm).

;; Associate Hamster files with `hamster-mode':
;;
;; (load-library "hamster-mode")
;; (add-to-list 'auto-mode-alist '("\\.hsc$" . hamster-mode))
;; (add-to-list 'auto-mode-alist '("\\.hsm$" . hamster-mode))

;; LIMITATIONS

;; If you want get rid of the `hamster-indent-line' add the following to
;; your .emcas:
;;
;; (add-hook 'hamster-mode-hook
;;		  '(lambda()
;;			 (setq indent-line-function 'insert-tab)))

;; The special line splitting technique with `_' is not supported.
;; See 'Syntax-Overview, Scripts' in Hamster.hlp.

;;; Code:

(require 'font-lock)

(defface hamster-bold-face '((t (:bold t)))
  "Hamster bold face")

(defvar hamster-bold-face 'hamster-bold-face
  "Hamster bold face")

(defvar hamster-mode-syntax-table nil
  "syntax table in use in hamster-mode buffers.")

(if hamster-mode-syntax-table
    ()
  (setq hamster-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?\\ "\\" hamster-mode-syntax-table)
  (modify-syntax-entry ?\n ">   " hamster-mode-syntax-table)
  (modify-syntax-entry ?\f ">   " hamster-mode-syntax-table)
  (modify-syntax-entry ?\# "<   " hamster-mode-syntax-table)
  (modify-syntax-entry ?/ "." hamster-mode-syntax-table)
  (modify-syntax-entry ?* "." hamster-mode-syntax-table)
  (modify-syntax-entry ?+ "." hamster-mode-syntax-table)
  (modify-syntax-entry ?- "." hamster-mode-syntax-table)
  (modify-syntax-entry ?= "." hamster-mode-syntax-table)
  (modify-syntax-entry ?% "." hamster-mode-syntax-table)
  (modify-syntax-entry ?< "." hamster-mode-syntax-table)
  (modify-syntax-entry ?> "." hamster-mode-syntax-table)
  (modify-syntax-entry ?& "." hamster-mode-syntax-table)
  (modify-syntax-entry ?| "." hamster-mode-syntax-table)
  (modify-syntax-entry ?_ "_" hamster-mode-syntax-table)
  (modify-syntax-entry ?\' "\"" hamster-mode-syntax-table))


(defvar hamster-mode-map
  (let ((map (make-sparse-keymap))
	(menu-map (make-sparse-keymap "Hamster")))
    (define-key map "\C-j"  'hamster-newline)
    (define-key map [menu-bar insert] (cons "Hamster" menu-map))
    (define-key menu-map [ham-if-endif]       '("if-endif" . ham-if-endif))
    (define-key menu-map [ham-if-else-endif]  '("if-else-endif" . ham-if-else-endif))
    (define-key menu-map [ham-for-endfor]     '("for-endfor" . ham-for-endfor))
    (define-key menu-map [ham-while-endwhile] '("while-endwhile" . ham-while-endwhile))
    (define-key menu-map [ham-do-loop]        '("do-loop" . ham-do-loop))
    (define-key menu-map [ham-repeat-until]   '("repeat-until" . ham-repeat-until))
    map)
  "Keymap used in hamster-mode.")

(defcustom hamster-indent 4
  "*This variable gives the indentation in Hamster mode."
  :type 'integer
  :group 'hamster)

;;;###autoload
(defun hamster-mode ()
  "Setup hamster mode"
  (interactive)
  (kill-all-local-variables)
  (use-local-map hamster-mode-map)
  (setq major-mode 'hamster-mode)
  (setq mode-name "Hamster")
  (set-syntax-table hamster-mode-syntax-table)
  (make-local-variable 'paragraph-start)
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'paragraph-ignore-fill-prefix)
  (setq paragraph-ignore-fill-prefix t)
  (make-local-variable 'require-final-newline)
  (setq require-final-newline t)
  (make-local-variable 'comment-start)
  (setq comment-start "# ")
  (make-local-variable 'comment-end)
  (setq comment-end "")
  (make-local-variable 'comment-column)
  (setq comment-column 32)
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "#+ *")

  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'hamster-indent-line)

  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults
	'((hamster-font-lock-keywords
	   hamster-font-lock-keywords-1)))

  ;; Nicht case sensitiv.
  (setq font-lock-defaults '(hamster-font-lock-keywords nil t))

  ;; Get the hooks.
  (run-hooks 'hamster-mode-hook))


(defconst hamster-font-lock-keywords-1
  (eval-when-compile
    (let ((ham-state
	   (regexp-opt
	    '("quit" "error" "assert" "return" "var" "label" "goto"
	      "if" "else" "end" "endif" "do" "while" "repeat" "else" "loop"
	      "endwhile""until" "for" "endfor" "break" "continue" "sleep"
	      "trace" "dump" "debug")))
	  (ham-sub
	   (regexp-opt
	    '("sub" "endsub")))
	  (ham-funcs-path
	   (regexp-opt
	    '("HamHscPath" "HamHsmPath" "HamLogsPath" "HamServerPath"
	      "HamGroupsPath" "HamMailPath" "HamNewsOutPath"
	      "HamMailsOutPath" "HamNewsErrPath")))
	  (ham-funcs-1
	   (regexp-opt
	    '("HamVersion" "HamPath" "HamMessage" "HamThreadCount"
	      "HamIsIdle" "HamWaitIdle" "HamFlush" "HamPurge"
	      "HamRebuildGlobalLists" "HamRebuildHistory" "HamSetLogin"
	      "HamNewsJobsClear""HamNewsJobsPullDef"
	      "HamNewsJobsPostDef" "HamNewsJobsPull" "HamNewsJobsPost"
	      "HamNewsJobsStart" "HamMailExchange" "HamFetchMail"
	      "HamSendMail" "HamSendMailAuth" "HamRasDial"
	      "HamRasHangup" "HamGroupCount" "HamGroupName" "HamGroupIndex"
	      "HamGroupOpen" "HamGroupClose" "HamArtCount" "HamArtNoMin"
	      "HamArtNoMax" "HamArtText" "HamArtTextExport" "HamArtImport"
	      "HamArtDeleteMid" "HamArtLocateMid" "HamScoreList"
	      "HamScoreTest" "HamGroupNameByHandle" "HamCheckPurge"
	      "HamGetStatus" "DeleteHostsEntry" "SetHostsEntry_ByName"
	      "SetHostsEntry_ByAddr" "HamNewsPull" "HamNewsPost")))
	  (ham-funcs-2
	   (regexp-opt
	    '(
	      ;; Variables
	      "set" "varset" "inc" "inc" "dec"

	      ;; Integers
	      "true" "false" "isint" "abs" "sgn"

	      ;; Strings
	      "isstr" "ord" "chr" "str" "hex" "len" "pos" "copy" "delete" "trim"
	      "lowercase" "uppercase" "replace" "eval"
	      "RE_Match" "RE_Extract" "RE_Parse" "RE_Split"

	      ;; Time
	      "ticks" "time" "timegmt" "decodetime" "encodetime"

	      ;; Error-handling
	      "ErrCatch" "ErrNum" "ErrMsg" "ErrModule" "ErrLineNo" "ErrLine"
	      "ErrSender"

	      ;; Files and directoriers
	      "execute" "IniRead" "IniWrite" "FileExists" "FileSize"
	      "FileTime" "FileDelete" "FileRename" "FileCopy" "DirExists"
	      "DirMake" "DirRemove" "DirChange" "DirCurrent" "DirWindows"
	      "DirSystem"

	      ;; List
	      "ListAlloc" "ListFree" "ListExists" "ListClear" "ListCount"
	      "HamArtText" "HamArtTextExport" "HamArtImport"
	      "ListGet" "ListSet" "ListGetTag" "ListSetTag" "ListGetKey"
	      "ListSetKey" "ListAdd" "ListDelete" "ListInsert" "ListSort"
	      "ListSetText" "ListGetText" "ListIndexOf" "ListLoad" "ListSave"
	      "ListFiles" "ListDirs" "ListRasEntries"

	      ;; Input/Output
	      "print" "warning" "MsgBox" "InputBox" "ListBox" "InputPW"
	      "AddLog"

	      ;; Sheduler
	      "AtClear" "AtAdd" "AtExecute"

	      ;; Ras
	      "RasGetConnection" "RasIsConnected" "RasDial" "RasHangup"
	      "RasGetIP" "RasLastError"

	      ;; Counter
	      "XCounter" "ClearXCounter" "SetXCounter" "IncXCounter"
	      "DecXCounter"

	      ;; Miscellaneous
	      "iif" "icase" "gosub"

	      ;; Miscellaneous II
	      "entercontext" "leavecontext"

	      ;; Miscellaneous III
	      "runscript" "paramcount" "paramstr" "SetTaskLimiter"
	      "GetTasksActive" "GetTasksWait" "GetTasksRun" "Localhostname"
	      "Localhostaddr"
	      )))
	  )
      (list
       (cons (concat "\\<\\(" ham-state "\\)\\>") 'font-lock-keyword-face)
       (cons (concat "\\<\\(" ham-sub "\\)\\>") 'hamster-bold-face)
       (cons (concat "\\<\\(" ham-funcs-path "\\)\\>") 'font-lock-function-name-face)
       (cons (concat "\\<\\(" ham-funcs-1 "\\)\\>") 'font-lock-function-name-face)
       (cons (concat "\\<\\(" ham-funcs-2 "\\)\\>") 'font-lock-function-name-face)

       (list (concat "\\<\\("
		     "\\\$"
		     "\\)")
	     1 'font-lock-variable-name-face)
       )))
  "Default expressions to highlight in Hamster mode.")

(defvar hamster-font-lock-keywords hamster-font-lock-keywords-1
  "")


(defun hamster-newline ()
  "Insert a newline and indent following line like previous line."
  (interactive)
  (let ((hpos (current-indentation)))
    (newline)
    (indent-to hpos)))

(defun hamster-indent-line ()
  "Experimental indent support. See hamster-mode.el how to disable"
  (interactive)
  (let ((hpos 'nil)
	(e-point 0))
    (save-excursion
      (beginning-of-line)
      (re-search-backward "[A-z|0-9].*$" nil t)
      (setq hpos (current-indentation))
      (end-of-line)
      (setq e-point (point))
      (beginning-of-line)
      (if (re-search-forward "\\(if\\|for\\|while\\) *?\(" e-point t)
	  (setq hpos (+ hpos hamster-indent))))
    (if (= 0 (current-column))
	(indent-line-to hpos)
      (save-excursion
	(indent-line-to hpos)))))


(defun ham-hs2 ()
  (interactive)
  (insert "#!hs2"))

(defun ham-initialize ()
  (interactive)
  (insert "#!initialize"))

(defun ham-load ()
  (interactive)
  (insert "#!load"))

(defun ham-if-endif ()
  (interactive)
  (insert "if( ")
  (save-excursion
    (insert " )\n\nendif\n")))

(defun ham-if-else-endif ()
  (interactive)
  (insert "if( ")
  (save-excursion
    (insert " )\n\nelse\n\nendif\n")))

(defun ham-for-endfor ()
  (interactive)
  (insert "for( ")
  (save-excursion
    (insert " )\n\nendfor\n")))

(defun ham-while-endwhile ()
  (interactive)
  (insert "while( ")
  (save-excursion
    (insert " )\n\nendwhile\n")))

(defun ham-do-loop ()
  (interactive)
  (insert "do\n")
  (insert "break{ ")
  (save-excursion
    (insert " )\n")
    (insert "continue()\n")
    (insert "loop")))

(defun ham-repeat-until ()
  (interactive)
  (insert "repeat\n\nuntil( ")
  (save-excursion
    (insert " )\n")))

(provide 'hamster-mode)
;;; hamster-mode.el ends here
