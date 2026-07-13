# Machete: unidades compartidas con Samba + AD

Pasos para crear una nueva carpeta compartida, respetando permisos de grupos de AD.

## 0. Prerrequisito: confirmar que el server está unido al dominio

```bash
sudo net ads testjoin
wbinfo -g | grep GG-NombreDelGrupo
getent group "GG-NombreDelGrupo"
```

Si estos dos últimos no devuelven nada, winbind no está resolviendo bien los
grupos de AD — resolver esto antes de seguir.

## 1. Crear la carpeta

```bash
sudo mkdir -p /srv/samba/NombreCarpeta
```

## 2. Permisos

```bash
sudo chown :GG-NombreDelGrupo /srv/samba/NombreCarpeta
sudo chmod 2770 /srv/samba/NombreCarpeta
```

## 3. Agregar el share en smb.conf

```bash
sudo nano /etc/samba/smb.conf
```

```ini
[NombreCarpeta]
   comment = Directorio de NombreCarpeta
   path = /srv/samba/NombreCarpeta
   valid users = @"GG-NombreDelGrupo", @"Domain Admins"
   read only = no
   guest ok = no
   force create mode = 0660
   force directory mode = 2770
```

Si Samba no resuelve `@"GG-Grupo"` sin prefijo de dominio, probar con:

```ini
valid users = @"PETROLBTH\GG-NombreDelGrupo", @"PETROLBTH\Domain Admins"
```

## 4. Validar la configuración antes de reiniciar

```bash
sudo testparm
```

## 5. Reiniciar servicios

```bash
sudo systemctl restart smbd nmbd winbind
```

## 6. Probar desde un cliente Windows

Logueado con un usuario miembro de `GG-NombreDelGrupo`:

```
\\<IP_del_servidor_samba>\NombreCarpeta
```
