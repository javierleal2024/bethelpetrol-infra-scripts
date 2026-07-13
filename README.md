# BethelPetrol-Corp — Infra Scripts

Scripts y documentación del lab de infraestructura simulada de BethelPetrol-Corp:
Active Directory, estructura de OUs, grupos de seguridad, importación masiva de
usuarios, y unidades compartidas con Samba.

Proyecto de práctica para DevOps / administración de sistemas, simulando la
infraestructura completa de una empresa (identidad, archivos, tickets) sobre
Windows Server + Ubuntu Server en arquitectura ARM (Macbook m3 air 24gb ram)

## Estructura

```
.
├── ad/
│   ├── 01-crear-ous.ps1              # Estructura de OUs geográfica
│   ├── 02-crear-grupos-seguridad.ps1 # Grupos de seguridad por departamento
│   └── 03-importar-usuarios.ps1      # Alta masiva de usuarios desde CSV
├── samba/
│   └── machete-unidades-compartidas.md
└── docs/
    └── fix-ldap-signing-server2025.md
```

## Arquitectura del lab

```
Windows Server 2025 (DC)  → AD DS, DNS, DHCP
Ubuntu Server (Samba)     → Archivos compartidos, unido al dominio
Ubuntu Server (Docker)    → GLPI, intranet, n8n, Open WebUI
```

## Diseño de OUs

```
BethelPetrol-Corp
├── 00-Admin
├── Usuarios
│   ├── CABA / Casa-Central
│   ├── Neuquén / Añelo, Rincón
│   └── Chubut / Comodoro-Rivadavia
├── Equipos
│   └── (misma geografía)
└── Grupos
    └── 20 grupos de seguridad por departamento
```

Decisión de diseño: geografía primero, tipo de objeto (Usuarios/Equipos) arriba
de todo — refleja un modelo de IT centralizado (Mesa de Ayuda administra todo
desde una sede central), no delegación regional.

## Orden de ejecución

1. `ad/01-crear-ous.ps1`
2. `ad/02-crear-grupos-seguridad.ps1` (requiere usuarios ya cargados para poblar grupos)
3. `ad/03-importar-usuarios.ps1` (ajustar ruta del CSV y ejecutar antes del paso 2
   si se quiere poblar grupos automáticamente en la misma corrida)

## Proyecto relacionado

La intranet corporativa (Node.js + login LDAP + API) vive en un repo separado:
[intranet-bethelpetrol](https://github.com/TU_USUARIO/intranet-bethelpetrol)
