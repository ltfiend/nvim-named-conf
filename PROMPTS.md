## 2026-06-01 18:11:10

First, please make sure git commits are recorded under my user (peter@devries.tv) not claude.

---

## 2026-06-01 18:13:59

Take a look at my nvim-ha-automations project.  I would like to do the same thing for named.conf files.  I would like a neovim plugin to have a build in LSP functionality, colorized file filters, hover text, etc.  I would also like the script to be able to run a named-checkconf on the file.  Allow the user to configure the command to run named-checkconf and any option flags (for chrooted directories etc).   Link to the ha project:  https://github.com/ltfiend/nvim-ha-automations

---

## 2026-06-02 09:17:45

I may have misclicked.  Please let me know of the current status of this effort.

---

## 2026-06-02 09:29:47

yes, continue where you left off.

---

## 2026-06-02 10:46:02

I need to take a step back.  You are using my local nvim install which is an older version.  I use my neodocker 'dockerized' neovim to do all of my work.  That version is either 0.12.2 or 0.13.x depending of if I am using nightly.  The plugin should use features in 0.12.2 but should also run regardless of neovim install or dockerized as long as the version is good.  neodocker command is sourced from .neodocker.rc

---

## 2026-06-03 10:31:26

take a look at my nvim-rndc-zone plugin.  What is the best way to make the named.conf LSP you just built work inside of that nvim-rndc-zone plugin.  If we need to split the named LSP off please do so

---

## 2026-06-03 20:54:55

I'd like you to make sure this project, especially the lsp has all the configuration options up to date in bind version 9.20.23.  The applicable ARM is located at https://bind9.readthedocs.io/en/v9.20.23/

---

## 2026-06-03 21:36:58

yep, let's do rndc as well.

---

## 2026-06-03 21:57:44

merge it to main and push

---

## 2026-06-05 22:40:19

<local-command-stdout>(no content)</local-command-stdout>

---

## 2026-09-10 00:33:37

add functionality that opens the output of man named.conf into a named.conf buffer so the user can hover text all the options

---

## 2026-09-10 00:59:13

push it

---

## 2026-09-10 08:10:30

I'm thinking this is a little much for this build.  I want to load the named.conf man page just to get a complete example of all configuration options so you can use hover text to learn about them.   Let's do it more efficently by just extracting the named.conf page from the installed BIND and create a method to load that into a immutable buffer where I can do hover text.   Seperately spin up an agent to make sure that all the hover text in the plugin is up to date with BIND 9.20.27.

---

