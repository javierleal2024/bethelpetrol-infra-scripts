# ============================================
# Crear estructura de OUs - BethelPetrol-Corp
# Ejecutar en el DC con el módulo ActiveDirectory
# ============================================

Import-Module ActiveDirectory

$DomainDN = "DC=PetrolBTH,DC=com"   # Ajustar según el dominio real

function Crear-OU {
    param([string]$Nombre, [string]$RutaPadre)
    $existe = Get-ADOrganizationalUnit -Filter "Name -eq '$Nombre'" -SearchBase $RutaPadre -SearchScope OneLevel -ErrorAction SilentlyContinue
    if (-not $existe) {
        New-ADOrganizationalUnit -Name $Nombre -Path $RutaPadre -ProtectedFromAccidentalDeletion $true
        Write-Host "Creada: OU=$Nombre,$RutaPadre" -ForegroundColor Green
    } else {
        Write-Host "Ya existe: OU=$Nombre,$RutaPadre" -ForegroundColor Yellow
    }
}

# Raíz de la empresa
Crear-OU -Nombre "BethelPetrol-Corp" -RutaPadre $DomainDN
$RaizCorp = "OU=BethelPetrol-Corp,$DomainDN"

# Nivel 2
Crear-OU -Nombre "00-Admin" -RutaPadre $RaizCorp
Crear-OU -Nombre "Usuarios" -RutaPadre $RaizCorp
Crear-OU -Nombre "Equipos"  -RutaPadre $RaizCorp
Crear-OU -Nombre "Grupos"   -RutaPadre $RaizCorp

# Estructura geográfica dentro de Usuarios y Equipos
$Estructura = @{
    "CABA"     = @("Casa-Central")
    "Neuquén"  = @("Añelo", "Rincón")
    "Chubut"   = @("Comodoro-Rivadavia")
}

foreach ($rama in @("Usuarios", "Equipos")) {
    $rutaRama = "OU=$rama,$RaizCorp"
    foreach ($provincia in $Estructura.Keys) {
        Crear-OU -Nombre $provincia -RutaPadre $rutaRama
        $rutaProvincia = "OU=$provincia,$rutaRama"
        foreach ($sede in $Estructura[$provincia]) {
            Crear-OU -Nombre $sede -RutaPadre $rutaProvincia
        }
    }
}

Write-Host "`n=== Estructura de OUs creada ===" -ForegroundColor Cyan
