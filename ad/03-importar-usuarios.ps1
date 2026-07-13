# ============================================
# Importar usuarios desde CSV a Active Directory
# CSV esperado: Nombre,SegundoNombre,Apellido,Provincia,Sede,Puesto,Departamento
# ============================================

Import-Module ActiveDirectory

$DomainDN = "DC=PetrolBTH,DC=com"
$CSVPath  = "C:\scrips\usuarios.csv"   # Ajustar ruta real
$Password = "Bethel2028!"

function Limpiar-Texto {
    param([string]$texto)
    $normalizado = $texto.Normalize([System.Text.NormalizationForm]::FormD)
    $sinAcentos = ($normalizado.ToCharArray() | Where-Object {
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark
    }) -join ''
    return $sinAcentos.ToLower() -replace '\s',''
}

function Generar-SamUnico {
    param($nombre, $segundoNombre, $apellido)

    $inicial = Limpiar-Texto $nombre.Substring(0,1)
    $apellidoLimpio = Limpiar-Texto $apellido
    $samBase = "$inicial$apellidoLimpio"

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$samBase'" -ErrorAction SilentlyContinue)) {
        return $samBase
    }

    if ($segundoNombre -and $segundoNombre.Trim() -ne "") {
        $inicial2 = Limpiar-Texto $segundoNombre.Substring(0,1)
        $samAlt = "$inicial2$apellidoLimpio"
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$samAlt'" -ErrorAction SilentlyContinue)) {
            return $samAlt
        }
    }

    $contador = 2
    do {
        $samNum = "$samBase$contador"
        $libre = -not (Get-ADUser -Filter "SamAccountName -eq '$samNum'" -ErrorAction SilentlyContinue)
        $contador++
    } while (-not $libre)
    return $samNum
}

$usuarios = Import-Csv -Path $CSVPath

foreach ($u in $usuarios) {
    $OUPath = "OU=$($u.Sede),OU=$($u.Provincia),OU=Usuarios,OU=BethelPetrol-Corp,$DomainDN"
    $nombreCompleto = "$($u.Nombre) $($u.SegundoNombre)".Trim()
    $displayName = "$nombreCompleto $($u.Apellido)"

    $ouExiste = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'" -ErrorAction SilentlyContinue

    if ($ouExiste) {
        $sam = Generar-SamUnico -nombre $u.Nombre -segundoNombre $u.SegundoNombre -apellido $u.Apellido
        $upn = "$sam@PetrolBTH.com"

        try {
            New-ADUser -Name $displayName `
                -GivenName $nombreCompleto `
                -Surname $u.Apellido `
                -DisplayName $displayName `
                -SamAccountName $sam `
                -UserPrincipalName $upn `
                -Path $OUPath `
                -Description $u.Puesto `
                -Department $u.Departamento `
                -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
                -Enabled $true `
                -PasswordNeverExpires $true

            Write-Host "Creado: $displayName ($sam) en $OUPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Error creando $displayName : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "OU no encontrada para $displayName : $OUPath" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Importación finalizada ===" -ForegroundColor Cyan
