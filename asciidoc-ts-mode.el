;;; asciidoc-ts-mode.el --- Major mode for editing AsciiDoc files using tree-sitter -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Dunaevskiy Maxim

;; Author: Dunaevskiy Maxim <dunmaksim@yandex.ru>
;; Created: May 2026
;; Keywords: asciidoc languages tree-sitter
;; Version: 0.1

;; This file is not a part of GNU Emacs.


;;; Commentary:

;; This file defines asciidoc-ts-mode which is a major mode for editing
;; Asciidoc files that uses Tree Sitter to parse the language.  More
;; information about Tree Sitter can be found in the ELisp Info pages
;; as well as this website: https://tree-sitter.github.io/tree-sitter/

;; For this major mode to work, Emacs has to be compiled with
;; tree-sitter support, and the Asciidoc grammar has to be compiled and
;; put somewhere Emacs can find it.  See the docstring of
;; `treesit-extra-load-path'.

;;; Code:

(require 'treesit)
(require 'faces)
(require 'font-lock)

(declare-function treesit-language-available-p "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-parser-create "treesit.c")

(defgroup asciidoc-ts nil
  "Major mode for viewing and editing Asciidoc buffers."
  :prefix "asciidoc-ts-"
  :group 'text
  :group 'editing
  :version "30.1")


;;; Faces:

(defgroup asciidoc-ts-faces nil
  "Faces used by Asciidoc-TS."
  :group 'asciidoc-ts
  :group 'faces)

(defface asciidoc-ts-heading-0 '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for level 0 Asciidoc headings."
  :version "30.1")

(defface asciidoc-ts-heading-1 '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for level 1 Asciidoc headings."
  :version "30.1")

(defface asciidoc-ts-heading-2 '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for level 2 Asciidoc headings."
  :version "30.1")

(defface asciidoc-ts-heading-3 '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for level 3 Asciidoc headings."
  :version "30.1")

(defface asciidoc-ts-heading-4 '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for level 4 Asciidoc headings."
  :version "30.1")

(defface asciidoc-ts-heading-5 '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for level 5 Asciidoc headings."
  :version "30.1")

(defface asciidoc-ts-macro-name '((t (:inherit font-lock-function-name-face)))
  "Face for block macro."
  :version "30.1")

(defface asciidoc-ts-delimiter '((t (:inherit shadow :slant normal :weight normal)))
  "Face for delimiter in block macro."
  :version "30.1")

(defface asciidoc-ts-macro-target '((t (:inherit font-lock-string-face)))
  "Face for target in block macro."
  :version "30.1")

(defface asciidoc-ts-attribute-name '((t (:inherit font-lock-variable-name-face)))
  "Face for block_macro attribute name."
  :version "30.1")

(defface asciidoc-ts-attribute-value '((t (:inherit font-lock-variable-use-face)))
  "Face for block_macro attribute value."
  :version "30.1")

(defface asciidoc-ts-block-quote '((t (:inherit font-lock-doc-face)))
  "Face for Asciidoc block quotes."
  :version "30.1")

(defface asciidoc-ts-emphasis '((t (:inherit italic)))
  "Face for Asciidoc emphasis (italic) text."
  :version "30.1")

(defface asciidoc-ts-bold '((t (:inherit bold)))
  "Face for Asciidoc strong emphasis (bold) text."
  :version "30.1")

(defface asciidoc-ts-code-block '((t (:inherit fixed-pitch :extend t)))
  "Face for Asciidoc fenced code block content.
Alter this face to add a `:background' for visually distinct
code block region, e.g.:
  (set-face-attribute \\='asciidoc-ts-code-block nil :background \"gray95\")"
  :version "30.1")

(defface asciidoc-ts-code-span '((t (:inherit (asciidoc-ts-code-block font-lock-constant-face))))
  "Face for Asciidoc inline code spans."
  :version "30.1")

(defface asciidoc-ts-link '((t (:inherit link)))
  "Face for Asciidoc link text."
  :version "30.1")

(defface asciidoc-ts-list-marker '((t (:inherit shadow :slant normal :weight normal)))
  "Face for Asciidoc list markers like -, * and •."
  :version "30.1")

(defface asciidoc-ts-table '((t (:inherit (asciidoc-ts-code-block) :extend t)))
  "Face for Asciidoc table.
Alter this face to add a `:background' for a visually distinct table
region, e.g.:
  (set-face-attribute \\='asciidoc-ts-table nil :background \"gray95\")"
  :version "31.1")

(defface asciidoc-ts-table-block-marker '((t (:inherit asciidoc-ts-table)))
  "Face for Asciidoc table block markers |===."
  :version "30.1")


(defface asciidoc-ts-admonition-note '((t (:inherit default)))
  "Face for Asciidoc NOTE admonition."
  :version "30.1")

(defface asciidoc-ts-admonition-tip '((t (:inherit success)))
  "Face for Asciidoc TIP admonition."
  :version "30.1")

(defface asciidoc-ts-admonition-important '((t (:inherit font-lock-warning-face)))
  "Face for Asciidoc IMPORTANT admonition.")

(defface asciidoc-ts-admonition-warning '((t (:inherit font-lock-warning-face)))
  "Face for Asciidoc WARNING admonition."
  :version "30.1")

(defface asciidoc-ts-admonition-caution '((t (:inherit error)))
  "Face for asciidoc CAUTION admonition."
  :version "30.1")


(add-to-list
  'treesit-language-source-alist
  '(asciidoc
     "https://github.com/cathaysia/tree-sitter-asciidoc"
     "v0.3.0" ;; Emacs 30
     "tree-sitter-asciidoc/src")
  t)

(add-to-list
  'treesit-language-source-alist
  '(asciidoc-inline
     "https://github.com/cathaysia/tree-sitter-asciidoc"
     "v0.3.0" ;; Emacs 30
     "tree-sitter-asciidoc_inline/src")
  t)


(defun asciidoc-ts-install-grammars ()
  "Install the Tree-Sitter grammars for AsciiDoc (run once)."
  (interactive)
  (treesit-install-language-grammar 'asciidoc)
  (treesit-install-language-grammar 'asciidoc-inline))


;;; Font-Lock:

(defvar asciidoc-ts-mode--font-lock-rules
  (treesit-font-lock-rules
    :language 'asciidoc
    :feature 'comment
    '((line_comment) @font-lock-comment-face
       (block_comment) @font-lock-comment-face)

    ;; Headings
    :language 'asciidoc
    :feature 'heading
    ;; = Document title (level 0 title)
    '((document_title
        (title_h0_marker) @asciidoc-ts-heading-0 ;; Bug in parser: document attrs parsed like a part of document header
        (line) @asciidoc-ts-heading-0)
       (title1) @asciidoc-ts-heading-1
       (title2) @asciidoc-ts-heading-2
       (title3) @asciidoc-ts-heading-3
       (title4) @asciidoc-ts-heading-4
       (title5) @asciidoc-ts-heading-5)

    ;; Document and element attributes
    :language 'asciidoc
    :feature 'attribute
    '((document_attr
        (document_attr_marker) @font-lock-delimiter-face
        (attr_name) @font-lock-variable-name-face
        (document_attr_marker) @font-lock-delimiter-face
        (line) @font-lock-variable-use-face)
       (element_attr
         (element_attr_marker) @font-lock-delimiter-face
         (attr_value) @font-lock-variable-name-face
         (element_attr_marker) @font-lock-delimiter-face))

    ;; Blocks
    :language 'asciidoc
    :feature 'block
    '((block_title) @font-lock-doc-face
       (listing_block
         (listing_block_start_marker) @font-lock-bracket-face
         (listing_block_body) @asciidoc-ts-code-span
         (listing_block_end_marker) @font-lock-bracket-face)
       (quoted_block
         (quoted_block_marker) @font-lock-bracket-face
         (line) @asciidoc-ts-block-quote
         (quoted_block_marker) @font-lock-bracket-face))

    ;; Lists
    :language 'asciidoc
    :feature 'list
    '((unordered_list_item
        (unordered_list_marker) @asciidoc-ts-list-marker)
       (ordered_list_item
         (ordered_list_marker) @asciidoc-ts-list-marker)
       (checked_list_item
         (checked_list_marker) @asciidoc-ts-list-marker))

    ;; Tables
    :language 'asciidoc
    :feature 'table
    '((table_block
        (table_block_marker) @asciidoc-ts-table-block-marker
        (table_cell) @asciidoc-ts-table
        (table_block_marker) @asciidoc-ts-table-block-marker))


    ;; Admonitions
    :language 'asciidoc
    :feature 'admonition
    '((admonition
        (admonition_note) @asciidoc-ts-admonition-note)
       (admonition
         (admonition_tip) @asciidoc-ts-admonition-tip)
       (admonition
         (admonition_important) @asciidoc-ts-admonition-important)
       (admonition
         (admonition_caution) @asciidoc-ts-admonition-caution)
       (admonition
         (admonition_warning) @asciidoc-ts-admonition-warning))

    ;; Macro
    :language 'asciidoc
    :feature 'macro
    '((block_macro
        (block_macro_name) @asciidoc-ts-macro-name
        "::" @asciidoc-ts-delimiter
        (target) @asciidoc-ts-macro-target)
       (block_macro_attr
         (attribute_name) @asciidoc-ts-attribute-name
         "=" @asciidoc-ts-delimiter
         (attribute_value) @asciidoc-ts-attribute-value))

    ;; Inline markup
    :language 'asciidoc-inline
    :feature 'markup
    '((emphasis) @asciidoc-ts-bold  ;; Why not bold? I don't know!
       (ltalic) @asciidoc-ts-emphasis ;; Typing error from parser! Don't fix here!
       (monospace) @asciidoc-ts-code-span
       (replacement) @font-lock-variable-use-face
       (inline_element
         (xref
           ("<<") @asciidoc-ts-link
           (id) @asciidoc-ts-link
           (">>") @asciidoc-ts-link)))

    ;; Macro
    :language 'asciidoc-inline
    :feature 'inline-macro
    '((inline_macro
        (macro_name) @font-lock-builtin-face
        (target) @success)
       (inline_macro
         (macro_name) @font-lock-builtin-face
         (attr) @font-lock-property-use-face)
       (inline_macro
         (macro_name) @font-lock-builtin-face
         (target) @success
         (attr) @font-lock-property-use-face)))
  "Tree-Sitter Font-Lock rules for `asciidoc-ts-mode'.")


;; IMenu
;; BUG: fix this code
(defvar asciidoc-ts-mode--imenu-rules
  '(("Headings"
      "heading"
      nil
      nil))
  "IMenu rules for `asciidoc-ts-mode'.")


(defun asciidoc-ts-mode--defun-name (node)
  "Return the heading text of NODE, used by `treesit-defun-name-function'."
  (when (string= (treesit-node-type node) "section_heading")
    ;; Grab the first title_h*_atx child
    (let ((title (treesit-node-child-by-field-name node "title")))
      (when title (treesit-node-text title t)))))


(defun asciidoc-ts-mode--fill-forward-paragraph (&optional arg)
  "Move forward ARG AsciiDoc paragraphs for filling."
  (let ((arg (or arg 1)))
    (dotimes (_ arg)
      (re-search-forward "\n\n+" nil t))))


;;;###autoload
(define-derived-mode asciidoc-ts-mode text-mode "AsciiDoc[ts]"
  "Major mode for AsciiDoc files, powered by Tree-sitter.

Uses the `asciidoc' and `asciidoc-inline' Tree-sitter grammars.
Install them once with \\[asciidoc-ts-install-grammars]."
  :group 'asciidoc-ts

  (unless (treesit-available-p)
    (error "Tree-sitter is not available in this Emacs build"))

  (setq-local treesit-range-settings
    (treesit-range-rules
      :host 'asciidoc
      :embed 'asciidoc-inline
      :local t
      '((line) @asciidoc-inline)))

  ;; Create parsers for both languages.
  ;; The block-level parser covers the whole buffer.
  ;; The inline parser is embedded inside paragraph/heading ranges.
  (treesit-parser-create 'asciidoc)
  ;; (treesit-parser-create 'asciidoc-inline)

  ;; Font-lock
  (setq-local treesit-font-lock-settings asciidoc-ts-mode--font-lock-rules)
  (setq-local treesit-font-lock-feature-list
    '(;; Level 1 – always on
       (comment block)
       ;; Level 2 – default on
       (heading attribute markup macro table)
       ;; Level 3 – default on
       (list inline-macro)
       ;; Level 4 – toggle with M-x font-lock-mode / customize
       (admonition)))

  ;; Imenu
  (setq-local treesit-simple-imenu-settings asciidoc-ts-mode--imenu-rules)

  ;; Structural navigation (M-a / M-e between headings)
  (setq-local treesit-defun-type-regexp "section_heading")
  (setq-local treesit-defun-name-function #'asciidoc-ts-mode--defun-name)

  ;; Sentence / paragraph movement
  (setq-local forward-paragraph-function #'asciidoc-ts-mode--fill-forward-paragraph)

  ;; Basic fill settings
  (setq-local fill-column 120)
  (setq-local adaptive-fill-regexp "[ \t]*")

  ;; Tabs are not meaningful in AsciiDoc
  (setq-local indent-tabs-mode nil)

  ;; Comment syntax (single-line comments only in AsciiDoc)
  (setq-local comment-start "// ")
  (setq-local comment-end "")

  (treesit-major-mode-setup))


;;;###autoload
(defun asciidoc-ts-mode-maybe ()
  "Enable `asciidoc-ts-mode' when its grammars are available."
  (if (and (treesit-language-available-p 'asciidoc)
        (treesit-language-available-p 'asciidoc-inline))
    (asciidoc-ts-mode)
    (text-mode)))

(add-to-list 'auto-mode-alist '("\\.adoc\\'"     . asciidoc-ts-mode-maybe))
(add-to-list 'auto-mode-alist '("\\.asciidoc\\'" . asciidoc-ts-mode-maybe))

(provide 'asciidoc-ts-mode)

;;; asciidoc-ts-mode.el ends here
