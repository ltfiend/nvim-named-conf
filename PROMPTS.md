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

