# WireGuard Manager — Didot404

> Bash CLI tool untuk manage WireGuard VPS hub + MikroTik client provisioner.
> Satu VPS sebagai hub, banyak MikroTik sebagai peer.

```
               +▒▒▒▒+  +▒▒▒+  ▒▒   ▒▒  ▒▒  +▒▒▒+  ▒▒
               ▒▒+---  ▒▒ ▒▒  ▒▒   ▒▒  ▒▒  ▒▒+--  ▒▒
               +▒▒▒+   ▒▒ ▒▒  ▒▒   ▒▒  ▒▒  +▒▒▒+  ▒▒
               ---▒▒▒  ▒▒ ▒▒  ▒▒   ▒▒--▒▒  --▒▒▒  ▒▒
               +▒▒▒▒+  +▒▒▒+  +▒▒  +▒▒▒▒+  +▒▒▒+  ▒▒

  ▒▒▒▒+   ▒▒  +▒▒▒▒+  ▒▒  ▒▒▒▒▒  +▒▒▒▒  ▒▒   ▒▒  +▒▒  +▒▒▒▒  ▒▒▒▒▒
  ▒▒  ▒▒  ▒▒  ▒▒  --  ▒▒   ▒▒       ▒▒  ▒▒   ▒▒▒ ▒▒▒  ▒▒+--   ▒▒
  ▒▒  ▒▒  ▒▒  ▒▒ +▒▒  ▒▒   ▒▒    +▒▒▒▒  ▒▒   ▒▒▒▒▒▒▒  ▒▒▒▒▒   ▒▒
  ▒▒  ▒▒  ▒▒  ▒▒  ▒▒  ▒▒   ▒▒    ▒▒  ▒  ▒▒   ▒▒ ▒▒▒▒  ▒▒+--   ▒▒
  ▒▒▒▒+   ▒▒  +▒▒▒▒+  ▒▒   +▒▒   +▒▒▒▒  +▒▒  ▒▒  +▒▒  +▒▒▒▒   +▒▒
```

---

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zlabkeeb/solusidigitalnet-wireguard/main/install.sh)
```

> Jalankan sebagai **root** atau dengan **sudo**.

---

## Fitur

- Banner ASCII + animasi spinner & progress bar
- Install WireGuard server otomatis (Ubuntu/Debian)
- Tambah client MikroTik — generate config RouterOS siap paste
- Manage IP route per client langsung dari halaman detail
- Kontrol WireGuard: aktifkan / matikan / restart / enable boot
- Live peer status — last handshake & transfer stats
- Auto backup `wg0.conf` sebelum setiap perubahan

---

## Menu Utama

```
  1)  Install WireGuard Server
  2)  Menu Client           (tambah, detail, route)
  3)  Kontrol WireGuard     (aktif/matikan/restart)
  4)  Lihat Status & Peers
  5)  Uninstall
  0)  Keluar
```

---


## Requirements

| | |
|---|---|
| OS | Ubuntu 20.04+ / Debian 11+ |
| Akses | root / sudo |
| Arch | x86\_64 / ARM64 |

Packages (`wireguard`, `wireguard-tools`, `iptables`) di-install otomatis.

---

> Made by [Veriyan Irvansyah ](https://facebook.com/veriyan404)