# 🔐 Sistema de Autenticación con API Keys

**Fecha:** 20 de Febrero de 2026  
**Versión:** 1.0  
**Estado:** ✅ Implementado

---

## 🎯 Propósito

Permitir que aplicaciones (Apps móviles, servicios, integraciones) accedan a los endpoints de la API sin necesidad de autenticación de usuario (JWT).

---

## 📊 Características

- ✅ **Sin expiración** - Las API Keys no expiran automáticamente
- ✅ **Revocables** - Se pueden desactivar en cualquier momento
- ✅ **Permisos granulares** - Control fino de qué puede hacer cada key
- ✅ **Auditables** - Registro de última vez usada
- ✅ **Por organización** - Opcionalmente asociadas a una organización
- ✅ **Seguras** - Generadas con `secrets.token_urlsafe()`

---

## 🔧 Arquitectura

### **Componentes:**

1. **Modelo:** `APIKey` en `api/models.py`
2. **Autenticación:** `APIKeyAuthentication` en `api/authentication.py`
3. **Permisos:** `HasAPIKeyPermission`, `IsAPIKeyOrAuthenticated` en `api/permissions.py`
4. **Admin:** Gestión visual en Django Admin

---

## 🎫 Modelo APIKey

```python
class APIKey(TimeStampedModel):
    name = models.CharField(max_length=100)              # Nombre de la app
    key = models.CharField(max_length=64, unique=True)   # API Key generada
    organization = models.ForeignKey(Organization, ...)  # Opcional
    is_active = models.BooleanField(default=True)        # Activa/Inactiva
    permissions = models.JSONField(default=dict)         # Permisos específicos
    last_used = models.DateTimeField(null=True)          # Última vez usada
    description = models.TextField(blank=True)           # Descripción
```

### **Campos:**

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `name` | CharField | Nombre descriptivo (ej: "App Visitantes") |
| `key` | CharField | API Key única (generada automáticamente) |
| `organization` | ForeignKey | Organización asociada (opcional) |
| `is_active` | Boolean | Si está activa o no |
| `permissions` | JSON | Permisos específicos en formato JSON |
| `last_used` | DateTime | Última vez que se usó |
| `description` | TextField | Descripción adicional |

---

## 🔑 Crear una API Key

### **1. Desde Django Admin:**

```
1. Ir a http://tu-dominio/admin/api/apikey/
2. Click en "Agregar API Key"
3. Llenar:
   - Nombre: "App Visitantes"
   - Descripción: "Aplicación móvil para agregar visitantes"
   - Organización: Seleccionar (opcional)
   - Permisos: {"can_add_visitor": true, "can_checkin": true}
   - Activa: ✓
4. Guardar
5. ⚠️ COPIAR la API Key que se muestra (no se mostrará completa de nuevo)
```

### **2. Desde Python Shell:**

```python
from api.models import APIKey, Organization

# Crear API Key
api_key = APIKey.objects.create(
    name="App Visitantes",
    description="App móvil para agregar visitantes a eventos",
    organization=Organization.objects.get(id=1),
    permissions={
        "can_add_visitor": True,
        "can_validate_supervisor": True
    }
)

print(f"API Key creada: {api_key.key}")
# Output: fvx_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### **3. Programáticamente:**

```python
import secrets

key = f"fvx_{secrets.token_urlsafe(40)}"
# Ejemplo: fvx_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

---

## 🔐 Usar API Key desde Frontend

### **1. Headers HTTP:**

```javascript
// Angular/TypeScript
const headers = new HttpHeaders({
  'X-API-Key': 'fvx_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0',
  'Content-Type': 'application/json'
});

this.http.post('https://api.example.com/api/visitor/add/', data, { headers })
  .subscribe(response => {
    console.log('Success:', response);
  });
```

```javascript
// Fetch API
fetch('https://api.example.com/api/visitor/add/', {
  method: 'POST',
  headers: {
    'X-API-Key': 'fvx_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(data)
});
```

```bash
# cURL
curl -X POST https://api.example.com/api/visitor/add/ \
  -H "X-API-Key: fvx_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0" \
  -H "Content-Type: application/json" \
  -d '{"supervisor_code": "ABC123", ...}'
```

---

## 🛡️ Configurar Endpoint para Usar API Key

### **Opción 1: Solo API Key**

```python
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from api.authentication import APIKeyAuthentication
from api.permissions import HasAPIKeyPermission

@api_view(['POST'])
@authentication_classes([APIKeyAuthentication])
@permission_classes([HasAPIKeyPermission])
def add_visitor(request):
    """Solo accesible con API Key válida"""
    # request.user = None (AnonymousUser)
    # request.auth = APIKey object
    
    api_key = request.auth
    print(f"Request desde: {api_key.name}")
    
    # Tu lógica...
    return Response({'success': True})
```

### **Opción 2: API Key O JWT**

```python
from api.authentication import APIKeyAuthentication
from api.permissions import IsAPIKeyOrAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication

@api_view(['POST'])
@authentication_classes([APIKeyAuthentication, JWTAuthentication])
@permission_classes([IsAPIKeyOrAuthenticated])
def add_visitor(request):
    """Accesible con API Key O con JWT Token"""
    
    if request.user and request.user.is_authenticated:
        # Autenticado con JWT
        print(f"Usuario: {request.user.username}")
    else:
        # Autenticado con API Key
        api_key = request.auth
        print(f"API Key: {api_key.name}")
    
    return Response({'success': True})
```

### **Opción 3: Con Permisos Específicos**

```python
from api.permissions import HasAPIKeyPermissionFor

@api_view(['POST'])
@authentication_classes([APIKeyAuthentication])
@permission_classes([HasAPIKeyPermissionFor])
def add_visitor(request):
    """Solo si la API Key tiene el permiso específico"""
    # Definir permiso requerido
    pass

# Agregar atributo a la vista
add_visitor.required_api_permission = 'can_add_visitor'
```

---

## 🎯 Permisos Disponibles

### **Permisos Sugeridos:**

```json
{
  "can_add_visitor": true,
  "can_validate_supervisor": true,
  "can_checkin": true,
  "can_checkout": true,
  "can_list_events": true,
  "can_view_tickets": true,
  "can_redeem_tickets": true
}
```

### **Verificar Permisos en la Vista:**

```python
@api_view(['POST'])
@authentication_classes([APIKeyAuthentication])
@permission_classes([HasAPIKeyPermission])
def add_visitor(request):
    api_key = request.auth
    
    # Verificar permiso específico
    if not api_key.has_permission('can_add_visitor'):
        return Response({
            'error': 'Esta API Key no tiene permiso para agregar visitantes'
        }, status=403)
    
    # Continuar...
```

---

## 🔒 Seguridad

### **Mejores Prácticas:**

1. **No expongas la key en código**
```javascript
// ❌ MAL
const API_KEY = "fvx_abc123...";

// ✅ BIEN
const API_KEY = environment.apiKey;  // Desde archivo de configuración
```

2. **Usa variables de entorno**
```typescript
// environment.ts
export const environment = {
  apiKey: 'fvx_abc123...'  // Nunca commitear este archivo
};
```

3. **Rota keys periódicamente**
```python
# Crear nueva key
new_key = APIKey.objects.create(name="App Visitantes v2", ...)

# Desactivar la anterior
old_key.is_active = False
old_key.save()
```

4. **Monitorea el uso**
```python
# Ver última vez usada
api_key = APIKey.objects.get(name="App Visitantes")
print(f"Última vez usada: {api_key.last_used}")
```

5. **Limita por organización**
```python
# Verificar que la key pertenece a la organización correcta
if api_key.organization != event.organization:
    return Response({'error': 'No autorizado'}, status=403)
```

---

## 📊 Endpoints Configurados

| Endpoint | Método | Auth Requerida | Permiso |
|----------|--------|----------------|---------|
| `/api/visitor/add/` | POST | API Key O JWT | - |
| `/api/supervisor/validate-code/` | POST | API Key O JWT | - |
| `/api/event-list/today/` | GET | API Key O JWT | - |
| `/api/person/check-rut/` | POST | API Key O JWT | - |

---

## 🧪 Testing

### **Postman:**

```
1. Crear nueva request
2. Headers:
   - Key: X-API-Key
   - Value: fvx_tu-api-key-aqui
3. Body (JSON):
   {
     "supervisor_code": "ABC123",
     "event_code": "CONF2026",
     ...
   }
4. Send
```

### **Python:**

```python
import requests

headers = {
    'X-API-Key': 'fvx_abc123...',
    'Content-Type': 'application/json'
}

response = requests.post(
    'http://localhost:8000/api/visitor/add/',
    headers=headers,
    json={
        'supervisor_code': 'ABC123',
        'event_code': 'CONF2026',
        'document_number': '12345678-9',
        'first_name': 'Juan',
        'last_name': 'Pérez'
    }
)

print(response.json())
```

---

## ⚠️ Errores Comunes

### **Error 401: API Key inválida**
```json
{
  "detail": "API Key inválida o inactiva"
}
```
**Solución:** Verificar que la key es correcta y está activa.

### **Error 403: Sin permisos**
```json
{
  "error": "Esta API Key no tiene permiso..."
}
```
**Solución:** Agregar el permiso necesario en el campo `permissions`.

### **Error: Header incorrecto**
```
Key debe ser: X-API-Key (case-sensitive)
```

---

## 🔄 Migración

```bash
# Aplicar migración
python manage.py migrate

# Output:
# Applying api.0023_apikey... OK
```

---

## 📚 Referencias

- **Modelo:** `/api/models.py` - `class APIKey`
- **Autenticación:** `/api/authentication.py`
- **Permisos:** `/api/permissions.py`
- **Admin:** `/api/admin.py` - `APIKeyAdmin`
- **Vistas:** `/api/visitor_views.py`

---

**Última actualización:** 20 de Febrero de 2026  
**Versión:** 1.0  
**Estado:** ✅ Implementado y Documentado
