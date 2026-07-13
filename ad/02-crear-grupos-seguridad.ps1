# ============================================
# Crear grupos de seguridad y poblarlos por Departamento
# ============================================

Import-Module ActiveDirectory

$DomainDN = "DC=PetrolBTH,DC=com"
$GruposOU = "OU=Grupos,OU=BethelPetrol-Corp,$DomainDN"

# Mapeo grupo -> departamento(s)
$Mapeo = @{
    "GG-Mesa-Ayuda"              = @("Mesa de Ayuda")
    "GG-SoporteSitio"            = @("Soporte en Sitio")
    "GG-RedesYTelecom"           = @("Redes y Telecomunicaciones")
    "GG-OperacionesIT"           = @("Operaciones IT")
    "GG-SeguridadInformatica"    = @("Seguridad Informática")
    "GG-Desarrollo"              = @("Desarrollo")
    "GG-Laboratorio"             = @("Laboratorio")
    "GG-Finanzas"                = @("Finanzas")
    "GG-RRHH"                    = @("RRHH")
    "GG-Compras"                 = @("Compras")
    "GG-Legales"                 = @("Legales")
    "GG-Administracion"          = @("Administración")
    "GG-Direccion"               = @("Dirección")
    "GG-Auditoria"               = @("Auditoría")
    "GG-Marketing"               = @("Marketing")
    "GG-ExploracionYProduccion"  = @("Exploración y Producción")
    "GG-OperacionesYacimiento"   = @("Operaciones de Yacimiento")
    "GG-HSE"                     = @("HSE")
    "GG-Mantenimiento"           = @("Mantenimiento")
    "GG-Logistica"               = @("Logística")
}

foreach ($grupo in $Mapeo.Keys) {

    $existe = Get-ADGroup -Filter "Name -eq '$grupo'" -SearchBase $GruposOU -ErrorAction SilentlyContinue
    if (-not $existe) {
        New-ADGroup -Name $grupo -Path $GruposOU -GroupScope Global -GroupCategory Security `
            -Description "Grupo de seguridad - $grupo"
        Write-Host "Grupo creado: $grupo" -ForegroundColor Green
    } else {
        Write-Host "Ya existe: $grupo" -ForegroundColor Yellow
    }

    foreach ($depto in $Mapeo[$grupo]) {
        $miembros = Get-ADUser -Filter "Department -eq '$depto'" -SearchBase "OU=Usuarios,OU=BethelPetrol-Corp,$DomainDN"
        foreach ($m in $miembros) {
            try {
                Add-ADGroupMember -Identity $grupo -Members $m.SamAccountName -ErrorAction Stop
                Write-Host "  + $($m.SamAccountName) agregado a $grupo" -ForegroundColor Cyan
            } catch {
                # ya es miembro
            }
        }
    }
}

Write-Host "`n=== Grupos creados y poblados ===" -ForegroundColor Cyan
