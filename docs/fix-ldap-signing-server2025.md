# Fix: GLPI / LDAP bind falla con "Strong(er) authentication required (8)" en Windows Server 2025

## Síntoma

Al probar la conexión LDAP desde GLPI (o cualquier cliente LDAP simple sin TLS), el bind falla con:

```
ldap_bind: Strong(er) authentication required (8)
additional info: 00002028: LdapErr: DSID-0C0903CA, comment: The server requires
binds to turn on integrity checking if SSL\TLS are not already active on the
connection, data 0, v6724
```

## Causa

Windows Server 2025 introduce una **segunda política**, separada de la clásica
"LDAP server signing requirements", que puede seguir forzando el signing aunque
la primera esté en "None":

- `Domain controller: LDAP server signing requirements` (clásica, existe hace años)
- `Domain controller: LDAP server signing requirements Enforcement` (nueva en Server 2025)

Si solo se configura la primera, la segunda puede seguir exigiendo el signing
por default, y el error persiste.

## Solución

En el DC, con `gpmc.msc`:

1. `Forest → Domains → <dominio> → Domain Controllers → Default Domain Controllers Policy` → Edit
2. `Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → Security Options`
3. Configurar:
   - `Domain controller: LDAP server signing requirements` = **None**
   - `Domain controller: LDAP server signing requirements Enforcement` = **Disabled**
4. Aplicar y reiniciar el servicio NTDS (este valor no se aplica en caliente):

```powershell
gpupdate /force
net stop ntds
net start ntds
```

## Verificación

Confirmar el valor en el registro:

```powershell
reg query "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v LDAPServerIntegrity
```

Debe devolver `0x1` (None).

Probar el bind directo, sin GLPI de por medio (aislar la app de la infraestructura):

```bash
ldapsearch -x -H ldap://<IP_DC>:389 -D "usuario@dominio.com" -W \
  -b "DC=dominio,DC=com" "(sAMAccountName=usuario)"
```

Un `result: 0 Success` confirma que el bind funciona.

## Nota de seguridad

Deshabilitar el enforcement de LDAP signing **reduce la seguridad** del DC,
haciendo posible ataques de LDAP relay. Es aceptable en un lab aislado, pero
en producción la solución correcta es implementar LDAPS (LDAP sobre TLS,
puerto 636) con un certificado válido, y mantener el signing/enforcement
activos.
